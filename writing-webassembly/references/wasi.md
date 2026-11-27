# WASI, runtimes and toolchains

Checked 2026-11-27 with nixpkgs' wasmtime 50.0.1, wasm-tools 1.263.0 and
Rust 1.99.1. Items marked *verified* were run in this skill's
[examples](../examples/); items marked *volatile* are the ones most likely to
change, so re-check them against the linked sources once the skill's review
date has passed. Everything else comes from primary documentation.

## Versions

| Version | Status (2026-11) | Rust target |
|---|---|---|
| WASI 0.1 ("preview 1") | Legacy, still the most widely supported | `wasm32-wasip1` (renamed from `wasm32-wasi` in 2024) |
| WASI 0.2 | Stable, superseded by 0.3; components built on the component model | `wasm32-wasip2` (emits a component) |
| WASI 0.3 | Current; ratified 2026-06-11. Native `async`, `stream` and `future` types; `wasi:io` removed. Runtimes that run 0.3 also run 0.2 components | `wasm32-wasip3` (*volatile*: its tier and first stable Rust release were unclear) |

Sources: [wasi.dev/releases](https://wasi.dev/releases),
[the WASI 0.3 announcement](https://bytecodealliance.org/articles/WASI-0.3),
the rustc platform-support pages for
[wasip1](https://doc.rust-lang.org/nightly/rustc/platform-support/wasm32-wasip1.html),
[wasip2](https://doc.rust-lang.org/nightly/rustc/platform-support/wasm32-wasip2.html)
and [wasip3](https://doc.rust-lang.org/nightly/rustc/platform-support/wasm32-wasip3.html).
WASI 0.3 patch releases are planned about every two months (*volatile*).

`wasm32-unknown-unknown` is plain Wasm with no WASI, used for browsers through
wasm-bindgen. A core module and a component are different binary formats;
`wasm-tools print` shows which one you have.

## Nothing is ambient

A WASI guest gets only what the host grants:

- **Files:** only directories preopened with `--dir HOST::GUEST`. A path
  outside every preopen fails with `No such file or directory (os error 44)`,
  which is WASI's ENOENT, and the same error appears for a path under a
  directory that was never preopened (*verified*). It never says "permission
  denied", so do not debug it as a permissions problem.
- **Environment:** only variables passed with `--env NAME=VALUE`. Wasmtime
  does not pass the host environment through (*verified*); `-S inherit-env`
  opts in.
- **Network:** off unless the host enables it (`-S inherit-network`,
  `-S tcp`, `-S udp`, `-S allow-ip-name-lookup`).
- **Threads and processes:** `std::thread::spawn` returns an error on the
  WASI Rust targets, and spawning processes is unsupported.

Preopen whole directories: preopens nested more than one level deep are
reported to confuse wasi-libc's path resolution (*researched*).

## There is no temporary directory

WASI has no temp-directory facility. A proposal to add one to `wasi:cli`
([PR #54](https://github.com/WebAssembly/wasi-cli/pull/54)) was closed
without merging on 2025-11-25 for lack of consensus (*volatile*: a future
proposal would live in the WebAssembly/wasi repository).

Consequences, all *verified* with Rust 1.99.1 on wasmtime 50.0.1:

- `std::env::temp_dir()` panics with `not supported by WASI yet`
  (`library/std/src/sys/paths/wasi.rs`). It never reads `TMPDIR`, so setting
  `TMPDIR` cannot fix it.
- `tempfile::tempdir()` and `tempfile::NamedTempFile::new()` call it, so they
  panic too.
- A Rust panic on these targets aborts: wasmtime prints the panic message,
  then `wasm trap: wasm unreachable instruction executed`, and exits 134.

The fix is to have the host provide the directory and the guest receive its
path:

```bash
wasmtime run --dir "$host_tmp::/tmp" --env APP_TEST_TMPDIR=/tmp app.wasm
```

In the guest, read `APP_TEST_TMPDIR` (pick a project-specific name) and use
`tempfile::Builder::new().tempdir_in(dir)`, or call
`tempfile::env::override_temp_dir(dir)` once at startup. Keep one helper that
every test uses, so no test reaches `tempdir()` directly.

Zig's `std.testing.tmpDir` creates `.zig-cache/tmp/<random>` relative to the
current directory, so a WASI test run needs the current directory preopened
(`--dir .`) (*researched* from source, not run).

## Running and testing under a runtime

- **Cargo:** set `CARGO_TARGET_WASM32_WASIP1_RUNNER` (or the `WASIP2` form)
  so `cargo test --target wasm32-wasip1` runs each test binary under wasmtime:

  ```bash
  export CARGO_TARGET_WASM32_WASIP1_RUNNER="wasmtime run --dir $host_tmp::/tmp --env APP_TEST_TMPDIR=/tmp"
  ```

- **Inside a Nix build,** wasmtime fails to create its cache under the
  nonexistent home directory. Set `HOME="$TMPDIR"` (*verified*) or pass
  `-C cache=n`.
- **Host-only runs prove nothing about WASI.** Run the suite under the WASI
  runner before reporting it green; filesystem, environment and threading
  differences only appear there.
- Wasmtime options go before the `.wasm` file; everything after it is passed
  to the guest as arguments.
- `wasmtime run --invoke FUNC module.wasm ARGS...` calls an export directly.
  With arguments it warns that this is experimental (*verified*).
- `wasmtime wast FILE.wast` runs WAST assertion scripts (*verified*).

Useful `-W` options on wasmtime 50: `fuel=N`, `epoch-interruption`,
`max-wasm-stack=N`, `max-memory-size=N`, `timeout=DURATION`,
`trap-on-grow-failure`, and, for deterministic execution,
`nan-canonicalization` and `relaxed-simd-deterministic`. Run
`wasmtime run --help` and `wasmtime run -W help` for the installed version.

## Proposals and features

- The Wasm 3.0 core specification was completed on 2025-09-17 and includes
  memory64, garbage collection, exception handling and tail calls
  ([announcement](https://webassembly.org/news/2025-09-17-wasm-3.0/)). Check
  each runtime's support before relying on one; Wasmtime's
  [proposal stability table](https://docs.wasmtime.dev/stability-wasm-proposals.html)
  lists its tiers.
- Threads (*volatile*): `wasi-threads` is legacy, kept for preview-1-only
  engines (Rust target `wasm32-wasip1-threads`); its successor,
  shared-everything threads, is not implemented in Wasmtime; cooperative
  threads for WASI 0.3 were still in development.
- Exceptions (*volatile*): Rust's default on WASI is `panic=abort`. Unwinding
  on Wasm needs nightly Rust and an exception-encoding choice that was still
  unsettled.

## Toolchains in nixpkgs

| Need | nixpkgs attribute (2026-11) |
|---|---|
| Runtime | `wasmtime` (50.0.1); also `wazero`, `wasmer`, `wasmedge` |
| Text, validation, components | `wasm-tools` (1.263.0); `wabt` (1.0.41) for `wat2wasm`/`wasm2wat` |
| Size optimization | `binaryen` (`wasm-opt`) |
| Bindings | `wit-bindgen`, `wasm-bindgen-cli` |
| Rust for `wasm32-wasip1` | `pkgsCross.wasi32.buildPackages.rustc`, linked with `-C linker=${pkgs.lld}/bin/wasm-ld -C linker-flavor=wasm-ld` (*verified*, fetched from the binary cache) |
| C for WASI | the `pkgsCross.wasi32` clang and wasilibc (*researched*) |

Pitfalls (*verified*):

- Plain `pkgs.rustc` ships standard libraries only for the host,
  `wasm32-unknown-unknown` and `wasm32v1-none`, not for WASI.
- `pkgs.pkgsCross.wasi32.rustc` refuses to evaluate: it asks for a compiler
  that runs on WASI. The compiler that runs on the host and targets WASI is
  `buildPackages.rustc` of that package set.
- Without the linker flags, rustc fails with ``linker `lld` not found``.

There is no nixpkgs attribute for `wasi-sdk`, `jco` or WAMR. A project that
already pins Rust through rust-overlay can add the `wasm32-wasip1` target to
that toolchain instead.
