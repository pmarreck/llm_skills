---
name: cross-platform-project-build-arch
description: Design or migrate Nix-required cross-platform builds, canonical executable implementations, target-separated outputs and application bundles. Use for nix build integration, CANONICAL_IMPL, build canonize, implementation/platform scope flags, PF/VARIANT layouts and wrong-platform binaries. Not a mandate to restructure a project during unrelated work.
---

# Cross-platform project build architecture

Use this convention when introducing or deliberately migrating a project's
build/output layout. Preserve intentional cross-build products. Loading this
skill does not authorize a fleet migration, global PATH edits, deletion, or
replacement of an upstream project's established build interface.

## Canonical Mecha platform names

The fleet naming contract (2026-10-23) is:

- `OS`: `linux`, `macos`, or `mswin` (all five characters).
- `ARCH`: `amd64` (AMD and Intel x86-64) or `arm64` (AArch64).
- `PF`: `<OS>-<ARCH>`, for example `linux-amd64` or `mswin-arm64`.
- `VARIANT`: `gnu` or `musl` where applicable; otherwise unset and omitted
  from paths. PF and PLATFORM remain OS-ARCH. VARIANT belongs to the selected
  build target, not necessarily the machine running the build.

The supported matrix is `macos-arm64`, `linux-amd64`, `linux-arm64`,
`mswin-amd64`, and `mswin-arm64`. A syntactically valid token is not proof that
the project supports that target. `macos-amd64` is outside the default matrix.
Use `ARCH`, not `CA`, which is ambiguous with Certificate Authority.

Use PF in project-controlled platform identifiers, artifact namespaces, build
output directories and PATH-facing directories. Translate explicitly at tool
boundaries: compiler triples such as `x86_64-linux-musl`, Rust targets and Nix
system names such as `x86_64-linux` keep the spellings their tools require.
Do not mechanically rename third-party identifiers or compiler-owned caches.

## CLI self-identification

Every CLI's one-line `--about` output includes its description, version and
canonical platform as `PF=<OS>-<ARCH>`. Include `VARIANT=gnu` or `VARIANT=musl`
separately where applicable; omit VARIANT entirely otherwise. For example:

```text
tool 1.2.3 — Inspect records; PF=linux-amd64 VARIANT=musl
tool 1.2.3 — Inspect records; PF=macos-arm64
```

Compiled executables derive these fields from the actual compilation target,
not the build host or runtime OS/ARCH/PF/PLATFORM/VARIANT environment variables.
This stays true under emulation and cross-compilation. Interpreted tools report
their execution platform with the same mappings; do not claim a compiled target
for portable source. Compiler triples may be supplementary diagnostic data but
never substitute for canonical PF. Preserve the one-line contract and existing
localization; platform tokens are stable identifiers, not translated text.

When migrating a CLI, test its actual `--about` output for exact PF, optional
VARIANT and one-line output. Include a conflicting runtime environment case for
compiled binaries, mapping cases across declared targets, and actual executable
checks on available native/emulated targets. Label cross-build-only evidence as
such; metadata tests alone do not prove a foreign executable runs.

## Select the host once, when constructing PATH

Expose project commands through:

```text
bin/<PF>/<command>         # native executable or generated symlink
bin/<command>              # portable script or optional Nix bootstrap fallback
```

For a given project, its host-specific directory precedes generic `bin/`.
Normalize Linux to `linux`, Darwin to `macos`, and native Windows/MSYS/MinGW/
Cygwin environments to `mswin`; normalize `x86_64`/`amd64`/`AMD64` to `amd64`,
and `aarch64`/`arm64`/`ARM64` to `arm64`. WSL uses Linux outputs. Detect the
execution environment, not the remote client or physical machine underneath it.
Reject unsupported native mappings explicitly rather than guessing a platform;
portable scripts may remain available.

Only the current platform's directory and generic `bin/` belong in automatic
project PATH discovery. Never recursively add `bin/` children. Do not
automatically admit project `result/bin`, `zig-out/bin`, release directories,
foreign platform directories, or caches. Preserve unrelated system/profile
paths, existing project precedence, and explicit development environments.
Shell setup must be idempotent, quote paths, and avoid expensive recursive
scans, Nix evaluation, compilation, or executable-header inspection.

The normal compiled-command path executes directly, with no added host-selector
wrapper process or per-invocation compatibility checks. Validate outputs during
build/publication instead. A copied Mac symlink can remain valid on Linux;
putting it beneath `bin/macos-arm64/` keeps it outside Linux PATH selection.
This is an accidental-misexecution control, not a sandbox or a guarantee against
explicitly invoking a foreign file.

Keep compiled products out of generic `bin/`. A script is portable only if its
interpreter and dependencies are portable too; a copied Nix store shebang is
not automatically valid on another machine. Native Windows entrypoints must
work with the intended shell and executable extensions; do not require Unix
symlink privileges or Bash merely to run a compiled Windows command.

## Separate the entrypoint from the complete build product

Namespace project-controlled outputs by PF and profile. Where ABI variants apply,
use `VARIANT` below PF: `<implementation>-out/<PF>/[<VARIANT>/]<profile>/`.
Brackets mean optional, not literal. Do not create empty, `none` or `default`
variant directories. Do not add VARIANT to automatic PATH discovery. Other
coexisting minimum-OS or CPU configurations need explicit, documented separation;
do not quietly overload the agreed gnu/musl vocabulary. Record the actual
compiler target and compatibility requirements in build metadata. For example:

```text
bin/linux-amd64/tool -> ../../zig-out/linux-amd64/musl/ReleaseFast/bin/tool
zig-out/linux-amd64/musl/ReleaseFast/
    bin/tool
    lib/
    include/
    share/
zig-out/macos-arm64/ReleaseFast/
    Applications/Example.app/
.nix-out/<PF>/<profile> -> /nix/store/...-package
.build-work/<PF>/<profile>/
dist/<version>/<PF>/
```

These are installation trees, not just loose compiler outputs. Retain compiler
caches separately (`.zig-cache/`, Cargo's cache/output tree, etc.). Mixed-language
projects assemble one product tree from their native build graphs. Zig's
`--prefix` selects its installation destination. Nix packages expose the same
product structure under `$out`; `.nix-out/` is a retained output link. Never
point a writable scratch prefix through a link into the immutable store.

The PATH-facing PF deliberately hides ABI and profile details.
Publication selects a compatible artifact and records what was selected.
OS/architecture alone cannot prove loader, libc, CPU-feature, minimum-OS, or
runtime-dependency compatibility. Do not publish `-mcpu=native` outputs as
universally portable within an architecture. Check actual headers and closure
requirements, not only directory names or producer-written metadata.

Keep generated products and publication symlinks out of Git, using narrow
ignore rules that preserve tracked portable scripts and intentional launchers.
Use relative links for local products. Nix links need retained output GC roots;
foreign store paths copied from another machine are not guaranteed to exist.
Building a cross target must not retarget another platform's entrypoint.
Publish only after success, preserve the previous working selection on failure,
and serialize competing publications. Do not delete unrecognized `bin/` files.

## Preserve application bundles

Treat a macOS `.app` directory as a complete product, retaining its executable,
resources, `Info.plist`, helpers, frameworks, permissions, internal links, and
signatures. Keep it under `Applications/` in its target/profile product tree.
A macOS-specific command in `bin/macos-arm64/` can launch the selected bundle
through `open`; a separate CLI can have a direct executable entrypoint.
Do not extract the inner executable as a substitute for the application.
GUI launchers are a platform-specific necessity, not a reason to wrap all CLIs.

Likewise retain Windows DLL/resource adjacency and Linux runtime resources.
Signing/notarization follows final bundle assembly; verify the distributed
product, not just an intermediate executable. Keep settings outside immutable
products. Release archives/installers belong in `dist/`, never on PATH.
Cross-compiling a binary does not prove that its bundle runs or is signed;
declare native builder/SDK/signing requirements and untested platforms honestly.

## Require Nix builds with thin commands

Owner decision, 2026-10-23: **`nix build` is the canonical build operation**.
Nix is required for development, CI and release builds, not an optional backend.
`flake.nix` and its lock file select toolchains, dependencies and package/check
outputs. Top-level `./build` selects those outputs, invokes `nix build`, then
verifies and publishes the resulting artifacts. Remove `--backend=direct`,
automatic non-Nix fallback and a parallel contributor build recipe during
migration. Missing Nix is an actionable error, never a reason to switch builders.

Keep language build graphs (`build.zig`, Cargo, CMake, etc.) as implementation
details called by derivations. Derivations never call a wrapper that recursively
invokes Nix. `nix develop` supplies tools for editing, debugging and running
prepared artifacts; compiling inside a devShell alone does not satisfy this
build contract. Targeted compiler diagnostics are experiments, not an alternate
supported build backend or release qualification. Use `writing-nix` for Nix code.

Expose compiled test prerequisites as Nix outputs too. `./test` prepares them
once through Nix, then runs the complete suite with disposable state; it must
not rebuild through a direct backend. Nix checks may run tests inside derivations
without recursively calling the outer preparation wrapper. Host-dependent GUI,
hardware and fresh performance checks can execute the Nix-built artifacts outside
the sandbox, with explicit results and the existing isolation/resource controls.

Build host and target remain distinct. Windows artifacts are built through Nix
on WSL or a suitable remote/cross builder; native Windows runtime tests remain
required where specified. Declare required macOS builders and SDKs honestly.
Credentialed signing/notarization may be a separate release step over a staged
Nix-built product; it cannot mutate the store or quietly replace the build.
Requiring Nix for builders does not require end users of distributed applications
to install Nix. Preserve portable release products and their runtime checks.

| Command | Contract |
|---|---|
| `./build` | Invoke nix build for the canonical implementation/current platform and publish compatible commands; optimized by default, explicit debug/test modes |
| `./build canonize IMPL` | Validate and record CANONICAL_IMPL, print confirmation, exit without building or switching commands |
| `./build --all-impls` / `--all-implementations` | Build every declared implementation for the current platform |
| `./build --all-plats` / `--all-platforms` | Build the canonical implementation for every declared platform |
| `./build --all` | Expand both implementation and platform scopes; equivalent to combining the two flags |
| `./run` | Ensure the selected host build is current, then launch that exact CLI or bundle |
| `./test` | Prepare exact prerequisites with Nix, then run all required suites; never test a stale PATH installation or publish into live project state |
| `./build-and-run` | Optional alias to `./run`; no independent build logic |

For multiple executable implementations or migration from `build-all`, read
[canonical implementations](references/canonical-implementations.md). It owns
selection-file handling, namespaced outputs, migration steps and acceptance
tests. Single-implementation projects need no artificial selection machinery.
`--all` covers declared supported combinations, not an invented full Cartesian
product and not every conceivable ABI. Report failures and unavailable required
builders explicitly; never silently present a partial matrix as complete.

Test graph dependencies need not invoke the literal `./build` script or package
every platform. Preserve project-required safety profiles; optimized does not
automatically mean removing runtime safety checks. Benchmarks identify their
profile explicitly.

For executable commands we name, separate words with hyphens (`build-all`,
`build-and-run`), never underscores (`build_all`, `build_and_run`). Project
directory names use underscores; executable names do not inherit that convention.
Preserve established upstream command names. When deliberately migrating a
legacy script, update its callers, tests, documentation and packaging together;
preserve compatibility only when the project's users require it. Do not rewrite
historical receipts to claim a new command name was used in an earlier run.

Reserve root `build` for the executable script. Put Xcode/CMake intermediate
directories under `.build-work/`; root `Build/` conflicts with `build` on
case-insensitive filesystems. Avoid all case-only filename distinctions.
Existing Make targets can delegate to the same graph. `make install` with a
configurable prefix/DESTDIR is compatible with Nix; do not assume `/usr/bin`.

## Optional Nix bootstrap

Automatic build/download on explicit command invocation is allowed when Nix
controls it. It is not required, and must not occur during shell startup.
An optional generic `bin/tool` may bootstrap a missing product, with the ready
native entrypoint taking precedence. Report useful progress/errors to stderr,
preserve arguments/stdin/signals/exit status, and execute the resolved output
path explicitly to avoid recursion. Do not fetch a shell installer instead.

If implementing this fallback, test shell command hashing, missing directories,
broken symlinks, concurrent first invocations and build failure. A shell may
continue using its cached fallback after publication; clear the relevant cache
or let the fallback directly reuse the completed product without reevaluating
Nix. State that tradeoff rather than claiming every warm invocation is direct.
No source-freshness polling on every normal CLI invocation; use `./build` or
`./run` when development requires a fresh build.

## Adoption and proof

Read [verification-and-migration](references/verification-and-migration.md)
before implementing this layout, migrating existing products or PATH, or
claiming conformance. Start with a CLI and a bundled GUI pilot before a fleet
rollout. Keep the approved design separate from implementation/test status.

## Primary references

- [Zig installation prefixes and build graph](https://ziglang.org/learn/build-system/)
- [Cargo target-separated outputs](https://doc.rust-lang.org/cargo/reference/build-cache.html)
- [Nix build output links](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-build)
- [Apple bundle structure](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html)
- [GNU staged installation](https://www.gnu.org/software/automake/manual/html_node/DESTDIR.html)
