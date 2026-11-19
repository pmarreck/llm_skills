---
name: writing-rust
description: Write, test, review, or debug Rust code. Focuses on current toolchain verification, type-driven completeness, ownership at FFI boundaries, and Nix-controlled builds.
---

# Writing Rust

Use the project's pinned toolchain and dependencies. Read its intent, Rust
version, Cargo features, and Nix derivations before changing the build. Run
`nix build` as the canonical build and the project's complete `./test` entry
point for verification. `cargo check` and focused tests are useful diagnostics
inside the declared Nix environment; they do not replace the project build
contract.

## Encode completeness in types

Prefer closed enums and exhaustive `match` expressions for finite domain
variants. Avoid wildcard arms when a newly added variant should force review.
Use one authoritative typed model to derive or serialize each external
representation. For event logs, for example, let the event enum and typed
fields drive internal handling, NDJSON serialization and human-readable output;
make missing representations compile-time failures where practical. Keep
serialization formats explicitly versioned when they are persisted or shared.

The compiler only checks paths represented in the type system. It does not
prove runtime data is valid, a serializer includes every semantically required
field, or all event variants are exercised. Add independent contract tests for
round trips, schema shape and output behavior. Avoid hand-maintained tuple
layouts or parallel string-key maps when a typed struct or enum can make
omission visible.

## Generating Rust with Lua

Lua long strings delimited by `[[` and `]]` end at the first `]]`, which can
occur in Rust indexing or array syntax. Use a matching long-bracket delimiter
whose closing sequence does not appear in the source: `[=[...]=]`, then
`[==[...]==]` or more equals signs as needed. Check the complete payload; the
one-equals form is not universally safe. A long string also discards one
newline immediately after its opener and normalizes line endings. If exact
bytes matter, read the source as data or use byte-preserving escapes instead.

## Ownership and effects

Make ownership and borrowing explicit at API boundaries. Prefer slices for
borrowed input and return owned values only when the caller needs ownership.
Keep lifetimes local and simple; do not add lifetime parameters speculatively.
Use `Result` for recoverable failures and preserve useful error context. Avoid
panics for malformed input or expected environmental failures.

Do not make code compile by cloning whole collections, wrapping every resource
in `Arc<Mutex<_>>`, or replacing error handling with `unwrap`/`expect`. Choose
the owner, data access boundary and failure behavior first. For new clones and
shared mutable state, check copied volume/frequency, lock scope/contention and
consistency; record the reason where the choice is non-obvious. Prefer the
simplest design that meets those requirements, without speculative frameworks.
Read [ownership, concurrency and panic traps](references/ownership-and-concurrency.md)
when introducing shared state, database access, borrowing workarounds or lint
policy. These are review triggers, not blanket bans on legitimate Rust tools.

At C FFI boundaries, arbitrary bytes are `(pointer, length)`, never assumed to
be NUL-terminated. Specify who allocates and frees each buffer, whether pointers
may be retained, and how errors cross the ABI. Do not unwind Rust panics across
C ABI boundaries. Catch or translate panics at the exported boundary where the
ABI contract requires containment; C++ exceptions and Zig panics also need
explicit boundary handling.

When a public ABI has CLI consumers or interchangeable core implementations,
use [multi-implementation-contracts](../multi-implementation-contracts/SKILL.md)
to make acceptance consumers link only the packaged ABI. Same-crate CLI tests
can stay green while the exported interface becomes unusable.

## Performance and verification

During implementation, ask whether each function is on a hot path. Once a hot
path first works correctly, declare an optimistic expected complexity and add
an enforced `./big_o` case. Use the shared `performance-profiling` skill; the
Rust `big_o` crate can infer from measurements and check model bounds, but it
does not discover or require declarations by itself.

Use `cargo fmt --check`, Clippy where configured, and focused Rust tests through
the project test path. Keep tests isolated and fast. A compile success is not
behavioral verification. Use property, differential, and exhaustive finite
domain checks where the contract supports them.

## Linux libc and dead code

Each project uses one libc for all of its Linux builds. Static musl is the
default; dynamic glibc is for programs that must load host GPU, display or
audio libraries (GUI and GPU applications). Neither may depend on a Nix
store path. The policy and its blocking gate live in
[writing-nix's runtime-independence gate](../writing-nix/references/consuming-build-outputs.md).
The musl items below were verified with rustc 1.97.0:

- **Static musl:** build with `pkgs.pkgsStatic.rustPlatform.buildRustPackage`,
  which uses a cached cross rustc for the musl target and links statically.
- **Never static glibc:** do not use `-C target-feature=+crt-static` on the gnu
  target. The standard library reaches `getaddrinfo` (`std::net`) and
  `getpwuid_r` (`std::env::home_dir`), which a static glibc still resolves
  through shared libraries at run time. Under Nix's linker wrapper the link
  failed outright ("DSO missing from command line").
- **glibc:** a Nix-built gnu binary names the store's loader and glibc, and
  references the newest glibc symbol versions. A standalone artifact needs
  the standard interpreter path, no store RUNPATH, and a declared glibc floor
  that the writing-nix gate checks.
- **Archives:** every C or Zig archive the program links must be built for
  the same libc.
- **Rust staticlibs:** each one carries its own standard library, so a Rust
  program cannot link another Rust staticlib. That pairing needs a shared
  library, which only test-only artifacts may use.
- Dead-code elimination: rustc emits a section per function and passes
  `--gc-sections` for executables. In the release profile, set `lto = true`
  (fat) and `codegen-units = 1` so cross-crate dead code is removed too.
  `opt-level = "s"` or `"z"` trades speed for size; adopt it only on
  measurement. `panic = "abort"` shrinks binaries further but changes how
  panics are contained at FFI boundaries, so treat it as a contract decision.
- Strip debug information (Nix's fixup phase does by default; otherwise set
  `strip = "debuginfo"`). Keep the symbol table when tests inspect it with
  `nm`.

## Dependency and toolchain policy

Rust 1.100.0 was released on 2026-11-12. When assessing that upgrade, read
[the 1.100 upgrade reference](references/rust-1.100.md) for inference and Cargo
layout changes. This records a verified release, not a requirement to use the
newest compiler. Check the current official release notes again for later work.

Distinguish the compiler selected by the Nix derivation from Cargo's
`rust-version` minimum supported Rust version (MSRV). Updating one does not
automatically update the other. Keep rustc, Cargo, Clippy, rustfmt and required
target standard libraries consistent through the declared Nix toolchain;
check native and cross-build routes for separate older compiler selections.

Before adding or changing a dependency, follow
[`writing-nix`](../writing-nix/SKILL.md) and its
[dependency-portability reference](../writing-nix/references/dependency-portability.md).
That reference defines the Rust/Cargo and Nix source model, lock/vendor hashes,
private sources, source staging and clean-build proof. Never commit absolute
machine paths, local file URLs, undeclared sibling checkouts, or an implicit
host Cargo cache dependency. Verify a clean, source-bounded `nix build`; a warm
local target directory or devShell-only build does not prove CI portability.

When a repeated Rust-specific mistake exposes a gap, make a small evidence-based
update to this skill with the Rust version and a minimal reproduction. Do not
copy project-specific workarounds or speculate about future compiler behavior.
