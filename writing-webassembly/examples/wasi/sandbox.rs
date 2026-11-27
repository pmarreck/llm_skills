use std::{env, fs, io::Write, process};

fn main() {
    // The guest path of the preopened directory arrives via the environment.
    let dir = match env::var("APP_TEST_TMPDIR") {
        Ok(d) => d,
        Err(_) => { eprintln!("APP_TEST_TMPDIR not set"); process::exit(2); }
    };
    let path = format!("{dir}/scratch.txt");
    let mut f = fs::File::create(&path).unwrap_or_else(|e| { eprintln!("create {path}: {e}"); process::exit(3) });
    f.write_all(b"hello sandbox").unwrap();
    drop(f);
    let back = fs::read_to_string(&path).unwrap();
    assert_eq!(back, "hello sandbox");
    println!("INSIDE_OK {back}");
    fs::remove_file(&path).unwrap();

    // Negative control: paths outside the preopens must fail.
    for outside in ["/etc/passwd", "/not-preopened/x.txt"] {
        match fs::File::open(outside) {
            Ok(_) => { println!("OUTSIDE_ALLOWED {outside}"); process::exit(4); }
            Err(e) => println!("OUTSIDE_DENIED {outside}: {e}"),
        }
    }
}
