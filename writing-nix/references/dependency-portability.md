# Portable Rust and Zig dependencies under Nix

Dependency declarations must describe inputs that a clean, authorized CI builder
can obtain. A source directory existing on one developer machine is not a pin.
This applies to packages, test helpers, benchmark tools, hooks invoked by checks
and generated source, not only to libraries linked into the final executable.

## Choose a source model

| Dependency | Portable declaration |
|---|---|
| Source in the same repository | Relative path that remains inside the exported source closure; include all required tracked files in source filters |
| Separate Rust repository | Cargo Git dependency pinned to a commit and locked/vendored by Nix, or pinned Nix source staged inside the Cargo build tree |
| Separate Zig package | Commit-addressed URL plus Zig package hash, with its transitive cache prefetched by Nix, or pinned Nix source staged for a relative ZON path |
| Separate repository exposing useful Nix outputs | Locked flake input; consume the appropriate output for the target or its declared source as required |
| Separate repository needed only as source | Locked flake input with `flake = false`, or a fixed-output Nix fetcher with revision and content hash |
| Private source | Same source models, with fetch credentials provisioned outside the repository and derivation; verify the CI identity has access |

Do not commit dependencies on `/home/...`, `/Users/...`, drive-letter/UNC paths,
`~/...`, caller environment expansion, literal `/nix/store/...` paths, `file://`
or `git+file://` sources, or a sibling checkout outside the repository. A hash
on a local path does not make that path obtainable elsewhere. `${pinnedInput}`
in a Nix derivation is a dependency reference; a copied literal store path is not.

Relative paths are not inherently bad: `crates/ui` referring to `../core` may
stay within the same tracked workspace. Resolve against the declaring manifest,
not the shell cwd. Check symlink targets and Nix source filters as well as `..`.
An ignored source directory created by shell setup is unavailable to a clean
Git-backed flake unless the derivation explicitly supplies it.

Preserve layout when packaging test scripts too. Interpolating
`${./tests/cli/check}` exports that individual file; it does not export sibling
helpers that the script locates relative to its own directory. Export a bounded
source tree containing the script and its tracked helpers, then invoke the script
inside that tree. Run the resulting Nix check, even when the checkout's `./test`
passes. This is a source-closure problem that manifest path lint cannot establish.

## Pin and stage a separate source

This schematic uses placeholders; replace them with an actual source revision:

```nix
inputs.engine = {
  url = "github:example/engine/<full-commit-id>";
  flake = false;
};
```

Commit the resulting flake.lock, including its revision/content metadata.
If the input is a flake whose outputs you need, leave `flake = false` out and
select an output for the correct build/host target. A repository having its own
flake does not mean a Rust or Zig consumer should depend on a compiled Nix
package when it actually needs module source.

In the derivation, stage the declared source into an explicit directory inside
the build tree before dependency collection and compilation. For example,
`deps/engine` may be supplied from the locked input. Stage the same layout for
offline vendoring, package compilation and checks. Keep mutable build caches
elsewhere; never write through a symlink into the Nix store. Include any required
subdirectories, generated manifests and transitive source, not just one file.

A committed language manifest may then refer to that stable build-relative path.
Because the directory may be absent from Git, document its exact manifest/path,
pinned input and staging operation in the project's dependency policy. Use the
hook's narrow supported exception schema when deployed; a comment or broad
ignore is not evidence that staging works. Require a clean Nix build to prove it.

DevShell conveniences may mirror the layout for editor tooling, but shellHook
symlinks are not the build implementation. CI must succeed without entering
an interactive shell or relying on a neighboring checkout.

## Rust

- Keep package identity separate from its local alias. Registry dependencies
  need a committed Cargo.lock for application/CI builds; a semver requirement
  alone is not an immutable resolution. Git dependencies should name the
  intended commit with `rev`; the lock must resolve that same source.
- Pin vendoring through the chosen Nix Rust builder: use `cargoHash`, or
  `cargoLock.lockFile` and the needed Git dependency `outputHashes`, or the
  equivalent pinned Crane dependency derivation. Hash roles differ; do not
  substitute a Git commit ID for a Nix content hash.
- Inspect workspace dependencies, target-specific dependencies, build/dev
  dependencies, patch tables and Cargo source-replacement configuration.
  A safe top-level manifest does not sanitize a nested workspace member.
- Use actual Cargo TOML parsing for checks. A `[lib] path = "src/lib.rs"` entry
  is not a dependency declaration. Comments and documentation strings are not
  dependencies either. Cargo supports several equivalent table forms.
- When Nix stages a path dependency, preserve the expected package/subdirectory
  layout before Cargo resolves or vendors it. If changing Git dependencies to
  paths changes the lockfile graph, make that transformation explicit and
  reproducible. Do not let an unlocked build silently repair the graph.
- Use locked/offline resolution during ordinary sandbox builds after declared
  fetches complete. Updating pins is an intentional source change, not a
  network fetch performed by a test or compiler invocation.

## Zig

- `build.zig.zon` dependencies use either `.url` with `.hash`, or `.path`.
  Pin a remote URL to the intended commit/archive and verify with the project's
  actual Zig version. Zig's package hash and Nix's fetch/cache hash serve
  different formats and purposes; record each in its own field.
- Prefetch the transitive Zig package tree using a declared fixed-output
  derivation or pinned fetchers and a correctly named system-package tree.
  The ordinary build then uses that offline cache/system directory with the
  flags supported by the pinned Zig version. Never depend on the user's
  populated global Zig cache.
- For a `.path` dependency supplied by Nix, stage it inside the declared build
  source closure, just as for Cargo. `build.zig` must consume that dependency
  rather than import an arbitrary absolute path or reach into a sibling repo.
- When dependencies change, update the ZON entries, Nix fetch/cache hashes,
  source staging and check derivations together. Use `fix-zig-deps-hash` for a
  genuine hash update after verifying source identity. Do not “fix” portability
  by clearing a host cache, disabling the sandbox or copying a private checkout.

## Private repositories

Verify access using the CI/builder fetch identity, not just the developer's
interactive Git session. Use the configured authenticated fetch mechanism and
exact locked source. Never place tokens, keys or credential-bearing URLs in
manifests, lockfiles, build logs or store inputs. Ordinary sandbox build phases
must not acquire credentials or access the network. If the source cannot be
fetched under the configured CI identity, report that missing provisioning;
do not substitute a server-local source directory or make the repository public.

## Mechanical controls and their limits

The global staged-dependency hook is owned by dotfiles. During adoption, verify
its actual deployment rather than assuming this document installs it. The hook
should parse staged standard manifests and lockfiles, normalize dependency
paths, inspect the staged tree/symlinks and reject host-local/escaping sources.
It must inspect the index, so a safe unstaged edit cannot conceal an unsafe
staged commit. Legitimate intra-repository paths and declared Nix staging need
positive controls alongside the rejection tests.

Nix and build scripts are programmable. Static lint cannot prove arbitrary
computed paths, network access or complete source closure. The authoritative
second control is a clean, source-bounded `nix build`/check on the required CI
identity with effective sandbox isolation, declared inputs and no ambient
sibling checkout/cache. Record the actual sandbox configuration; a successful
build on a host with sandboxing disabled is not that evidence. No `--impure`,
extra host mount or broad exception merely to make the check pass.

Required regression examples include staged/worktree disagreement, valid sibling
workspace members inside the root, root escapes, POSIX/Windows/local URL paths,
symlink escapes, comments/quoted syntax, renamed/deleted manifests and an exact
Nix-staged dependency exception. Verify real commit rejection in disposable
repositories and then a successful clean build for the repaired dependency.

## Sources

- [Cargo dependency specification](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [Nixpkgs Rust packaging](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md)
- [Zig package manifest specification](https://github.com/ziglang/zig/blob/master/doc/build.zig.zon.md)
- [Zig build system](https://ziglang.org/learn/build-system/)

Reviewed 2026-10-23. Match options and schemas to the project's pinned tools;
upstream master documentation can describe a newer compiler/builder.
