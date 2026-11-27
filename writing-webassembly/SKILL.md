---
name: writing-webassembly
description: Write, build, test, debug or review WebAssembly (Wasm, WASM), WASI programs, and WAT or WAST text. Covers WASI's capability model and its missing temp directory (Rust's std::env::temp_dir and tempfile::tempdir panic on WASI), WASI 0.1/0.2/0.3 and wasm32-wasip1/wasip2/wasip3 targets, running tests under Wasmtime, WAT operand order, WAST tests, embedding untrusted Wasm with fuel limits, and offline Nix builds. Use for .wat, .wast or .wasm files, wasm32 targets, WASI or component-model work, or a Wasm runtime host; not merely for serving an already-built .wasm file.
---

# Writing WebAssembly

Researched on **2026-11-27** with nixpkgs' wasmtime 50.0.1, wasm-tools
1.263.0 and Rust 1.99.1. The [examples](examples/) build and run under
wasmtime offline in this repository's CI.

Review after: **2027-02-27**. WASI is under active development. Past that
date, re-verify every fact marked *volatile* in [WASI](references/wasi.md)
against its linked source before relying on it, in particular whether WASI
has gained a temporary-directory facility, then update this date and the
research date.

## Know which WebAssembly you are targeting

Decide these before writing code, because the answers change the toolchain,
the binary format and what the guest can do:

- **Browser or WASI?** Browser code targets plain Wasm
  (`wasm32-unknown-unknown`) and talks to JavaScript. WASI code runs in a
  runtime such as Wasmtime and gets system access only through WASI.
- **Which WASI?** 0.1 (`wasm32-wasip1`) is legacy but the most widely
  supported; 0.2 (`wasm32-wasip2`) and the current 0.3 build components on
  the component model. A core module and a component are different binary
  formats; check which one a runtime or tool expects.
- **Which runtime and version?** Read the project's pins and run
  `wasmtime --version`. Runtime flags and proposal support change monthly.

Read [WASI](references/wasi.md) for the version table, targets and runtime
flags.

## WASI grants nothing by default

A WASI guest sees only what the host passes in: directories preopened with
`--dir HOST::GUEST`, environment variables passed with `--env`, and network
access only if enabled. Wasmtime does not inherit the host environment, so a
`TMPDIR` set on the host is invisible to the guest. A path outside every
preopen fails with `No such file or directory`, not a permission error.

## There is no temporary directory

This is the WASI failure agents hit most often. WASI has no temp-directory
facility, and on the Rust WASI targets `std::env::temp_dir()` panics with
`not supported by WASI yet` without ever reading `TMPDIR`. Everything built on
it panics the same way, including `tempfile::tempdir()` and
`NamedTempFile::new()`. Setting `TMPDIR` cannot fix it.

Have the host preopen a directory and tell the guest its path:

```bash
wasmtime run --dir "$host_tmp::/tmp" --env APP_TEST_TMPDIR=/tmp app.wasm
# Cargo: export CARGO_TARGET_WASM32_WASIP1_RUNNER="wasmtime run --dir $host_tmp::/tmp --env APP_TEST_TMPDIR=/tmp"
```

In the guest, route every temporary file through one helper that reads that
variable and calls `tempfile::Builder::new().tempdir_in(dir)`, or call
`tempfile::env::override_temp_dir(dir)` once at startup. Then no test can
reach `tempdir()` by accident. [temp_dir_trap.rs](examples/wasi/temp_dir_trap.rs)
shows the panic and the fix side by side.

## Test under the real runtime

- Run the test suite under the WASI runner, not only on the host, before
  reporting it green. Filesystem, environment, threading and panic behavior
  differ, and host runs hide all of it.
- On the Rust WASI targets panics abort: a failing assertion ends the whole
  test binary with a Wasm `unreachable` trap (exit 134 under wasmtime).
  `std::thread::spawn` and process spawning return errors.
- Inside a Nix build, set `HOME="$TMPDIR"` (or pass `-C cache=n`) so
  wasmtime can create its cache.
- Test hand-written WAT with WAST scripts run by `wasmtime wast`, against the
  unchanged production module. Make test hosts validate the values they
  receive, and gate CI on the real host. See
  [WAT and testing](references/wat-and-testing.md).

## WAT essentials

- Instructions pop operands in push order: the left operand goes first.
  Negation is `i32.const 0`, then the value, then `i32.sub`; the reverse
  order computes `value - 0` and keeps the sign. The folded form
  `(i32.sub (i32.const 0) (local.get $x))` makes the order visible.
- Signedness lives in the instruction (`div_s`/`div_u`, `lt_s`/`lt_u`,
  `shr_s`/`shr_u`). Integer division by zero and signed `INT_MIN / -1` trap.
- Validate with `wasm-tools validate` and convert with `wasm-tools parse` and
  `wasm-tools print`.

## Embedding untrusted Wasm

When a host runs guest code (plugins, hot-reloaded applications), give every
call a fuel or epoch budget sized per call rather than per request, and bound
memory and stack. Treat a trap as an error the host reports. Keep guest
`.wat`/`.wasm` files out of the host's Nix source closure so a guest edit does
not rebuild the host. In browsers, recreate JavaScript views of linear memory
after anything that can grow it. Read [embedding](references/embedding.md).

## Determinism

Floating-point NaN bit patterns and relaxed-SIMD results can differ between
engines. Simulations and replays should keep state in integers or fixed
point. Wasmtime offers `-W nan-canonicalization` and
`-W relaxed-simd-deterministic`, and fuel gives a reproducible execution
bound.

## Nix builds

nixpkgs packages `wasmtime`, `wasm-tools`, `wabt`, `binaryen`, `wazero` and
the bindings generators. Plain `pkgs.rustc` cannot build for WASI; use
`pkgs.pkgsCross.wasi32.buildPackages.rustc` with
`-C linker=${pkgs.lld}/bin/wasm-ld -C linker-flavor=wasm-ld`, as
[default.nix](examples/default.nix) does, or add the target to an existing
rust-overlay toolchain. See [WASI](references/wasi.md#toolchains-in-nixpkgs).

## Worked examples

[default.nix](examples/default.nix) defines three checks that CI builds and
runs offline; each fails if its example misbehaves.

- [math.wat](examples/wat/math.wat) with
  [math-tests.wast](examples/wat/math-tests.wast): operand order, negation, a
  checked add that traps on overflow, and division traps, asserted against
  the production module.
- [sandbox.rs](examples/wasi/sandbox.rs): a WASI program writing inside a
  preopened directory whose path arrives through the environment, with paths
  outside it denied and a run without the preopen failing.
- [temp_dir_trap.rs](examples/wasi/temp_dir_trap.rs): `std::env::temp_dir()`
  panicking even with `TMPDIR` set, and the injected-directory fix.
