//! keyring-rs key-custody helper (Phase 108, T2 — A3 spike + app key custody).
//!
//! Keys live ONLY in the OS keychain (never a plaintext file), reached through
//! keyring-rs. This binary is the empirical proof that the round-trip works on
//! macOS and the same mechanism the app uses to store/retrieve provider keys.
//!
//! Commands:
//!   keyhelper roundtrip <service> <account> <secret>   set -> get -> delete; prints the got secret
//!   keyhelper store     <service> <account> <secret>   set a secret
//!   keyhelper get       <service> <account>            print a secret
//!   keyhelper delete    <service> <account>            delete a secret
//!
//! Exit codes: 0 ok, 1 keyring error, 2 usage error.

use keyring::Entry;
use std::env;
use std::process::exit;

fn entry(service: &str, account: &str) -> Entry {
    match Entry::new(service, account) {
        Ok(e) => e,
        Err(e) => {
            eprintln!("entry error: {e}");
            exit(1);
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 4 {
        eprintln!("usage: keyhelper <roundtrip|store|get|delete> <service> <account> [secret]");
        exit(2);
    }
    let cmd = args[1].as_str();
    let service = &args[2];
    let account = &args[3];
    let e = entry(service, account);

    match cmd {
        "roundtrip" => {
            let secret = args.get(4).map(String::as_str).unwrap_or("");
            // set -> get -> delete in ONE process so the keychain ACL never
            // prompts across separate process identities. Prints the GOT value
            // so the caller can assert it equals what was stored.
            if let Err(err) = e.set_password(secret) {
                eprintln!("set error: {err}");
                exit(1);
            }
            let got = match e.get_password() {
                Ok(pw) => pw,
                Err(err) => {
                    eprintln!("get error: {err}");
                    exit(1);
                }
            };
            // Best-effort cleanup; do not fail the round-trip on a delete error.
            let _ = e.delete_credential();
            println!("{got}");
        }
        "store" => {
            let secret = args.get(4).map(String::as_str).unwrap_or("");
            if let Err(err) = e.set_password(secret) {
                eprintln!("set error: {err}");
                exit(1);
            }
            println!("OK");
        }
        "get" => match e.get_password() {
            Ok(pw) => println!("{pw}"),
            Err(err) => {
                eprintln!("get error: {err}");
                exit(1);
            }
        },
        "delete" => match e.delete_credential() {
            Ok(_) => println!("OK"),
            Err(err) => {
                eprintln!("delete error: {err}");
                exit(1);
            }
        },
        other => {
            eprintln!("unknown command: {other}");
            exit(2);
        }
    }
}
