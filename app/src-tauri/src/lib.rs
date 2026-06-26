use keyring::Entry;

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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![store_secret, get_secret])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
