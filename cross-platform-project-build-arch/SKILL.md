---
name: cross-platform-project-build-arch
description: Design or migrate cross-platform build scripts, target-separated output trees, PATH-facing executables, and application bundles. Use for copied wrong-platform binaries, Nix/native build alignment, bin or zig-out layout, and build/run/test command conventions. Not a mandate to restructure a project during unrelated work.
---

# Cross-platform project build architecture

Use this convention when introducing or deliberately migrating a project's
build/output layout. Preserve intentional cross-build products. Loading this
skill does not authorize a fleet migration, global PATH edits, deletion, or
replacement of an upstream project's established build interface.

## Select the host once, when constructing PATH

Expose project commands through:

```text
bin/<os>/<arch>/<command>   # native executable or generated symlink
bin/<command>              # portable script or optional Nix bootstrap fallback
```

For a given project, its host-specific directory precedes generic `bin/`.
Use `linux`, `macos`, and `windows`; normalize `Darwin` to `macos`, `arm64` to
`aarch64`, and `amd64`/`AMD64` to `x86_64`. WSL uses Linux outputs. Detect the
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
putting it beneath `bin/macos/aarch64/` keeps it outside Linux PATH selection.
This is an accidental-misexecution control, not a sandbox or a guarantee against
explicitly invoking a foreign file.

Keep compiled products out of generic `bin/`. A script is portable only if its
interpreter and dependencies are portable too; a copied Nix store shebang is
not automatically valid on another machine. Native Windows entrypoints must
work with the intended shell and executable extensions; do not require Unix
symlink privileges or Bash merely to run a compiled Windows command.

## Separate the entrypoint from the complete build product

Use a target triple, including ABI where relevant, and an explicit profile
for real outputs. For example:

```text
bin/linux/x86_64/tool -> ../../../zig-out/x86_64-linux-musl/ReleaseFast/bin/tool
zig-out/x86_64-linux-musl/ReleaseFast/
    bin/tool
    lib/
    include/
    share/
zig-out/aarch64-macos/ReleaseFast/
    Applications/Example.app/
.nix-out/<target>/<profile> -> /nix/store/...-package
.build-work/<target>/<profile>/
dist/<version>/<target>/
```

These are installation trees, not just loose compiler outputs. Retain compiler
caches separately (`.zig-cache/`, Cargo's cache/output tree, etc.). Mixed-language
projects assemble one product tree from their native build graphs. Zig's
`--prefix` selects its installation destination. Nix packages expose the same
product structure under `$out`; `.nix-out/` is a retained output link. Never
point a writable direct-build prefix through a link into the immutable store.

The PATH-facing OS/architecture pair deliberately hides ABI and profile details.
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
A macOS-specific command in `bin/macos/aarch64/` can launch the selected bundle
through `open`; a separate CLI can have a direct executable entrypoint.
Do not extract the inner executable as a substitute for the application.
GUI launchers are a platform-specific necessity, not a reason to wrap all CLIs.

Likewise retain Windows DLL/resource adjacency and Linux runtime resources.
Signing/notarization follows final bundle assembly; verify the distributed
product, not just an intermediate executable. Keep settings outside immutable
products. Release archives/installers belong in `dist/`, never on PATH.
Cross-compiling a binary does not prove that its bundle runs or is signed;
declare native builder/SDK/signing requirements and untested platforms honestly.

## Use one build graph with thin commands

Keep the native build graph authoritative (`build.zig`, Cargo, CMake, etc.).
Nix pins toolchains/dependencies and packages that graph. For projects adopting
this convention, top-level `./build` defaults to Nix and may expose an explicit
`--backend=direct` path; document the equivalent native command so Nix is not
required for contributors. Derivations call the native builder, never a wrapper
that recursively calls Nix. Use the `writing-nix` skill when editing Nix code.

| Command | Contract |
|---|---|
| `./build` | Build and publish the compatible host product; optimized by default, explicit debug/test modes |
| `./build-all` | Build the declared target matrix; report failures and unavailable native builders; preserve the selected host entrypoint |
| `./run` | Ensure the selected host build is current, then launch that exact CLI or bundle |
| `./test` | Run unit/integration/CLI suites against their exact build dependencies; never accidentally test another PATH installation |
| `./build-and-run` | Optional alias to `./run`; no independent build logic |

Test graph dependencies need not invoke the literal `./build` script or package
every platform. Preserve project-required safety profiles; optimized does not
automatically mean removing runtime safety checks. Benchmarks identify their
profile explicitly. Prefer hyphenated executable names (`build-all`, not
`build_all`); preserve compatibility only when the project's users require it.

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
