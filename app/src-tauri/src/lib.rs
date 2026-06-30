use keyring::Entry;
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::sync::Mutex;
use tauri::{Emitter, Manager};
use tauri_plugin_dialog::DialogExt;

// Key custody commands (T2). The renderer never sees a raw key: it asks the
// shell to store/fetch by (service, account); the secret lives in the OS
// keychain via keyring-rs. The agent's file/shell tools cannot reach the
// keychain (see src/security/secret-deny.ts — the read-deny list). The keyring
// round-trip is proven against the macOS Keychain by src-tauri/keyhelper.

#[tauri::command]
fn store_secret(service: String, account: String, secret: String) -> Result<(), String> {
    let entry = Entry::new(&service, &account).map_err(|e| e.to_string())?;
    entry.set_password(&secret).map_err(|e| e.to_string())
}

#[tauri::command]
fn get_secret(service: String, account: String) -> Result<String, String> {
    let entry = Entry::new(&service, &account).map_err(|e| e.to_string())?;
    entry.get_password().map_err(|e| e.to_string())
}

// Engine-host bridge (Phase 109, T6). The webview is a browser and cannot run the
// Node-only engine (Pi/gate/memory/checkpoint/context). The Rust shell spawns the
// engine-host sidecar and relays its line protocol: every stdout line is emitted
// to the webview as a `host-message` event, and the `engine_send` command writes
// a line to the sidecar's stdin. Rust does the spawning, so the WEBVIEW capability
// manifest stays `core:default` (no shell/fs grant) and connect-src stays 'self'.
struct EngineHostProc {
    stdin: Mutex<Option<ChildStdin>>,
    // Kept so the child can be killed + replaced on a workspace change (T4) and is
    // not reaped while the app runs.
    child: Mutex<Option<Child>>,
}

#[tauri::command]
fn engine_send(state: tauri::State<EngineHostProc>, line: String) -> Result<(), String> {
    let mut guard = state.stdin.lock().map_err(|e| e.to_string())?;
    let stdin = guard.as_mut().ok_or("engine host not running")?;
    writeln!(stdin, "{line}").map_err(|e| e.to_string())?;
    stdin.flush().map_err(|e| e.to_string())
}

/// The engine-host sidecar script path (set by `npm run app`), or None if unset.
fn host_script() -> Option<String> {
    match std::env::var("NANA_ENGINE_HOST_JS") {
        Ok(s) if !s.is_empty() => Some(s),
        _ => None,
    }
}

/// Spawn the node engine-host sidecar and wire its stdout to `host-message`
/// events. `workspace`, when set, becomes the child's NANA_WORKSPACE — the gate
/// root the sidecar builds createHostGate from. Returns the child's stdin handle +
/// the Child, or None if the spawn failed.
fn spawn_sidecar(
    app: &tauri::AppHandle,
    script: &str,
    workspace: Option<&str>,
) -> Option<(ChildStdin, Child)> {
    let mut cmd = Command::new("node");
    cmd.arg(script)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit());
    if let Some(ws) = workspace {
        // Set BOTH the gate root (NANA_WORKSPACE, read by main.ts) and the process
        // cwd, so the sidecar's process.cwd() agrees with Pi's session cwd
        // (workspaceRoot). Otherwise a RELATIVE search/secret path resolves against
        // app/ in the gate but against the workspace in Pi (Ph114 review, F2/B-2).
        // The script path is absolute (NANA_ENGINE_HOST_JS), so current_dir is safe.
        cmd.env("NANA_WORKSPACE", ws).current_dir(ws);
    }

    let mut child = match cmd.spawn() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[nana] failed to spawn engine host ({script}): {e}");
            return None;
        }
    };

    let stdout = child.stdout.take().expect("piped stdout");
    let stdin = child.stdin.take().expect("piped stdin");
    let handle = app.clone();
    std::thread::spawn(move || {
        let reader = BufReader::new(stdout);
        for line in reader.lines().map_while(Result::ok) {
            // Every HostOutbound line is forwarded verbatim; the webview's
            // BridgeClient parses and routes by message `type`.
            let _ = handle.emit("host-message", line);
        }
    });

    Some((stdin, child))
}

fn spawn_engine_host(app: &tauri::AppHandle) -> EngineHostProc {
    let empty = || EngineHostProc {
        stdin: Mutex::new(None),
        child: Mutex::new(None),
    };

    let Some(script) = host_script() else {
        eprintln!(
            "[nana] NANA_ENGINE_HOST_JS not set; engine host not spawned \
             (the window launches but is not drivable — run `npm run app`)."
        );
        return empty();
    };

    // Initial spawn: no NANA_WORKSPACE override — the sidecar defaults to its cwd.
    // A workspace change (pick_workspace, T4) re-spawns with the chosen root.
    match spawn_sidecar(app, &script, None) {
        Some((stdin, child)) => EngineHostProc {
            stdin: Mutex::new(Some(stdin)),
            child: Mutex::new(Some(child)),
        },
        None => empty(),
    }
}

// Workspace picker + re-spawn (Phase 114, T3/T4). The webview NEVER supplies the
// workspace root: the gate auto-allows in-workspace writes, so the chosen folder
// IS the free-write zone, and a webview-supplied path would relocate the gate
// boundary. So the native folder dialog is opened HERE, in Rust — `pick_workspace`
// takes no path argument. Opening the dialog from Rust also keeps the capability
// manifest dialog-free (a Rust-side call bypasses the webview ACL), so the
// renderer gains no dialog/fs/shell reach.
//
// On a chosen folder we kill the running sidecar and re-spawn it with
// NANA_WORKSPACE=<chosen>. A FRESH process means a fresh createHostGate(root) and a
// fresh approved-writes Map — the new gate boundary is the chosen folder and no
// prior in-workspace approval carries over. Returns the chosen path, or None if
// the user cancelled (the running sidecar is left untouched).
//
// Per the dialog plugin docs, `blocking_pick_folder` must not run on the main
// thread; an `async` command runs on the async runtime (off the main thread). An
// async command that borrows State must return a Result (Tauri's lifetime rule);
// no lock is held across an await (there is none), so the std Mutex is fine.
#[tauri::command]
async fn pick_workspace(
    app: tauri::AppHandle,
    state: tauri::State<'_, EngineHostProc>,
) -> Result<Option<String>, String> {
    let chosen = app
        .dialog()
        .file()
        .blocking_pick_folder()
        .and_then(|p| p.into_path().ok())
        .map(|p| p.to_string_lossy().into_owned());

    let Some(root) = chosen else {
        return Ok(None); // cancelled — leave the running sidecar in place
    };

    let script = host_script().ok_or("NANA_ENGINE_HOST_JS not set")?;
    let (new_stdin, new_child) =
        spawn_sidecar(&app, &script, Some(&root)).ok_or("failed to re-spawn engine host")?;

    // Swap in the fresh child + stdin. Hold the stdin lock across BOTH swaps (stdin
    // then child — the only site that takes both, so no lock-order inversion with
    // engine_send, which takes stdin only): engine_send therefore never observes the
    // dead pipe mid-swap — it sees the old stdin or the new, never a torn state
    // (Ph114 review, F3). Killing the old child ends its stdout reader thread (stdout
    // closes); reap it off-thread so it does not linger as a zombie (F1) — wait()
    // must not block this async command.
    {
        let mut stdin_guard = state.stdin.lock().map_err(|e| e.to_string())?;
        {
            let mut child_guard = state.child.lock().map_err(|e| e.to_string())?;
            if let Some(mut old) = child_guard.take() {
                let _ = old.kill();
                std::thread::spawn(move || {
                    let _ = old.wait();
                });
            }
            *child_guard = Some(new_child);
        }
        *stdin_guard = Some(new_stdin);
    }

    Ok(Some(root))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            let proc = spawn_engine_host(app.handle());
            app.manage(proc);
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            store_secret,
            get_secret,
            engine_send,
            pick_workspace
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
