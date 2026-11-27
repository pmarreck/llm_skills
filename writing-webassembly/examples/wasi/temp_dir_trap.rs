// WASI has no system temporary directory. On wasm32-wasip1, Rust's
// std::env::temp_dir() panics with "not supported by WASI yet" and never reads
// TMPDIR, so tempfile::tempdir() fails the same way. The host must preopen a
// directory and tell the guest its path; with the tempfile crate, call
// tempfile::Builder::new().tempdir_in(path) or tempfile::env::override_temp_dir.
use std::{env, fs};

fn main() {
    if let Ok(dir) = env::var("APP_TEST_TMPDIR") {
        // The working pattern: use the injected, preopened path.
        let work = format!("{dir}/work-1");
        fs::create_dir(&work).unwrap();
        fs::write(format!("{work}/f"), b"x").unwrap();
        fs::remove_dir_all(&work).unwrap();
        println!("INJECTED_DIR_OK {dir}");
    } else {
        // The trap: this panics even when the host sets TMPDIR.
        println!("calling temp_dir");
        let t = env::temp_dir();
        println!("UNREACHABLE {t:?}");
    }
}
