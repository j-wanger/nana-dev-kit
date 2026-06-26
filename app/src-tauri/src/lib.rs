use keyring::Entry;
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, Command, Stdio};
use std::sync::Mutex;
use tauri::{Emitter, Manager};

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
    // Kept alive so the child process is not reaped while the app runs.
    _child: Mutex<Option<Child>>,
}

#[tauri::command]
fn engine_send(state: tauri::State<EngineHostProc>, line: String) -> Result<(), String> {
    let mut guard = state.stdin.lock().map_err(|e| e.to_string())?;
    let stdin = guard.as_mut().ok_or("engine host not running")?;
    writeln!(stdin, "{line}").map_err(|e| e.to_string())?;
    stdin.flush().map_err(|e| e.to_string())
}

fn spawn_engine_host(app: &tauri::AppHandle) -> EngineHostProc {
    let none = || EngineHostProc {
        stdin: Mutex::new(None),
        _child: Mutex::new(None),
    };

    let script = match std::env::var("NANA_ENGINE_HOST_JS") {
        Ok(s) if !s.is_empty() => s,
        _ => {
            eprintln!(
                "[nana] NANA_ENGINE_HOST_JS not set; engine host not spawned \
                 (the window launches but is not drivable — run `npm run app`)."
            );
            return none();
        }
    };

    let mut child = match Command::new("node")
        .arg(&script)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[nana] failed to spawn engine host ({script}): {e}");
            return none();
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

    EngineHostProc {
        stdin: Mutex::new(Some(stdin)),
        _child: Mutex::new(Some(child)),
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            let proc = spawn_engine_host(app.handle());
            app.manage(proc);
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![store_secret, get_secret, engine_send])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
