# Verification and migration

These are acceptance scenarios for implementations of the convention. Reading
this document, matching its wording, or creating correctly named directories
does not establish that a project's build or PATH behavior passes them.

## Scope and inventory

1. Read project instructions, intent, status, native build graph, package rules
   and helper scripts. Inspect the scoped `bin/`, `zig-out/`, `result` and
   bundle paths without traversing all projects or the Nix store.
2. Classify tracked scripts, generated host products, intentional cross-builds,
   release packages, fixtures and unknown files. Preserve cross-builds. Filename
   extensions and executable permission bits alone are insufficient classifiers.
3. Record current command resolutions and required entrypoints. Coordinate with
   the owner of shell PATH changes; do not race an active editor or another agent.
4. Agree the scope, target matrix, selected profiles and rollback before moving
   products. Use recoverable moves or known rebuild paths approved by the owner.
   A skill invocation does not authorize deleting binaries or rewriting a fleet.

## PATH selection scenarios

Use a temporary home/project corpus with an injectable OS and architecture.
Place distinguishable harmless fixture commands in generic and target-specific
directories. Exercise the actual path-construction implementation, then resolve
and invoke commands in isolated shells; do not duplicate its algorithm in tests.

- Linux x86_64 selects only Linux x86_64 plus portable commands; macOS aarch64
  selects only macOS aarch64 plus portable commands. Cover Linux aarch64 and
  native Windows architectures using their supported shell adapters.
- Normalize Darwin, arm64, AMD64 and the implementation's supported aliases.
  WSL selects Linux. Unknown platforms do not silently default to Linux/x86_64.
- With the same command in generic and host-specific locations, the native one
  wins. Preserve the intended precedence between different projects and against
  system/Nix development environments. No empty PATH components.
- A copied foreign-platform link points to an existing fixture but its parent
  directory is excluded. Raw project `result/bin`, `zig-out/bin`, arbitrary
  nested `bin` directories and distribution products remain excluded.
- Paths containing spaces work; repeated sourcing is idempotent. Legacy raw
  output paths already present in inherited PATH are dealt with explicitly,
  without stripping unrelated Nix profiles or user-specified paths.
- Opening a shell does not compile, evaluate Nix, or recursively inspect output
  files. Assert no calls to those operations using recording stubs, not sleeps.
- Decide whether missing host directories are included or created by setup.
  Test publishing the first product into an already-open shell. If re-sourcing
  or rehashing is needed, document it; do not claim immediate discovery otherwise.

Fixtures test selection; they do not prove foreign machine code cannot execute.
Use independently inspected real binary headers for publication checks, then
native runtime tests on each available target. Never execute arbitrary inventoried
binaries just to discover their architecture.

## Build and publication scenarios

- Build the host CLI, then a foreign target and a different profile. Confirm
  outputs coexist and the originally selected host command remains unchanged.
- Force a build/verification failure and prove the previous entrypoint still
  works. Test competing publication attempts without timing-dependent sleeps.
- Inspect ELF, Mach-O (including universal slices), or PE headers and runtime
  dependencies. Do not accept a manifest copied from the build command as the
  only target oracle. Check declared libc/loader and CPU baseline assumptions.
- Changing flags/toolchains cannot reuse stale intermediates incorrectly.
  Native and Nix build destinations cannot overwrite one another or write
  through a store symlink. Generated output/links are ignored without hiding
  source-controlled portable scripts or launchers.
- A direct command launch adds no architecture-selector process. If performance
  is measured, compare direct binary and published entrypoint on the same host;
  do not present shell PATH lookup itself as zero work.
- `./test` resolves exact products and runs its complete non-benchmark/non-fuzz
  suite; stale executables elsewhere on PATH cannot turn a broken build green.
- Native Windows execution does not depend on Unix symlink privileges. Test on
  Windows; a Linux cross-compile is only compile evidence. Likewise label macOS
  runtime/signature tests pending until performed on macOS.

## Bundles and releases

- Launch the assembled macOS bundle from a directory with spaces. Verify a
  resource load and required helper execution, not just the main binary's
  existence. Check signatures on the final distributable where applicable.
- Preserve bundle-relative links, executable modes, resources and frameworks
  across packaging/extraction. Windows DLL/resource lookup gets equivalent
  runtime coverage. Do not flatten directory products into `bin/`.
- Build-script names and intermediate directories coexist on a case-insensitive
  filesystem. A Linux directory listing cannot prove this.
- Shipping, updating, signing, notarization and activation are separate steps
  with their own authorization and verification. This layout alone establishes
  none of them.

## Rollout order

First stage and verify host-specific entrypoints for the scoped projects. Then
switch automatic PATH discovery to the new directories, remove obsolete admitted
paths, and recheck every recorded command resolution. Coordinate this order with
the dotfiles owner; an uncoordinated global PATH cutover can hide unmigrated tools.
Preserve rollback until the owner has verified the migrated commands.

Pilot a small CLI and one resource-bearing application bundle. Record commands,
target/profile, test results, platforms actually exercised and outstanding gaps.
Only then propose the next scoped batch; no automatic fleet-wide migration.
