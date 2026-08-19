# Derivations and packaging

## Dependency roles

Classify dependencies by where they execute and what consumes them:

| Attribute | Role |
|---|---|
| `nativeBuildInputs` | tools and setup hooks that run on the build machine |
| `buildInputs` | libraries and other inputs linked or consumed for the host target |
| `checkInputs` | tools needed only while running checks |
| `nativeCheckInputs` | check tools that execute on the build machine |

Set `strictDeps = true` when possible. It catches misplaced dependencies and
turns native builds into better predictors of cross builds. A tool in
`buildInputs` may appear to work natively and become unexecutable when the host
and build platforms differ.

## Derivation structure

Use final attributes when one attribute depends on an overridable sibling:

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.2.3";
  src = fetchFromGitHub {
    owner = "example";
    repo = finalAttrs.pname;
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };
})
```

A `rec` self-reference captures the original value and does not follow
`overrideAttrs`. Prefer `overrideAttrs`; `overrideDerivation` operates after
`mkDerivation` processing and loses useful structure.

Avoid top-level `with`, angle-bracket lookup paths such as `<nixpkgs>`, and
unquoted URL literals. Pin inputs explicitly and keep dependencies visible at
the point of use.

## Phases, hooks, and tests

- Use standard phases unless the upstream build truly cannot fit them.
- Preserve setup-hook arrays such as `cmakeFlagsArray`; replacing a phase can
  discard behavior supplied by Nixpkgs hooks.
- Run `patchShebangs` over scripts executed or installed by the derivation.
  Linux's Nix sandbox has no `/usr/bin/env`; Darwin usually does, so a Darwin
  pass does not prove Linux portability.
- Put build-time tests in `doCheck = true` with `checkInputs`. Put tests that
  require the installed output in `doInstallCheck = true` with
  `installCheckInputs`.
- Give tests private `HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`,
  `XDG_DATA_HOME`, and `XDG_STATE_HOME` directories. Set `XDG_RUNTIME_DIR` to a
  private directory with mode `0700`.
- Run the project suite inside a pure Nix environment. Do not preserve the
  caller's `PATH`, which can hide undeclared dependencies.

## Avoid evaluation-time builds

Passing a derivation output to filesystem-reading builtins causes
import-from-derivation (IFD). This includes less obvious calls such as
`builtins.pathExists`, `readFile`, `readDir`, `builtins.path`, and `import`.
Evaluation pauses until the derivation is built, and multiple discoveries can
serialize evaluation. Move the decision into a derivation or provide metadata
as ordinary evaluation input.

## Language dependency trees

Keep language lock files authoritative and convert network dependency
resolution into a declared fixed-output step. Do not fetch from the network in
the normal build sandbox.

For large Rust builds, separate dependency artifacts from source-sensitive
work with `crane.buildDepsOnly`, cargo-chef, or an equivalent. Source filtering
alone does not prevent dependency recompilation. If the output contains a known
binary set, write an explicit install phase rather than allowing a generic
Cargo install hook to copy a large cross-target tree.

For CUDA projects, supply one coherent toolkit containing `nvcc`, headers, and
libraries, then set `CUDAToolkit_ROOT` explicitly. CMake 4.3 and later no longer
fall back to `PATH` after that variable is set. Keep generated CMake flags in
the hook-provided arrays.

When a workaround or overlay compensates for an upstream problem, include:

1. a probe that fails without the workaround;
2. a probe that proves the workaround has an effect;
3. the upstream issue or owner;
4. a removal condition.

## Assumptions overturned

- “`rec` makes an internally consistent package after overrides.” Its sibling
  references keep their original values; `finalAttrs` follows overrides.
- “`pathExists` is a cheap evaluation predicate.” On a derivation output it is
  IFD and may build before evaluation continues.
- “A script that ran on macOS has a portable shebang.” Linux's Nix sandbox
  lacks `/usr/bin/env` until `patchShebangs` rewrites it.
- “Source filtering gives Rust dependency caching.” Cargo still sees source
  changes unless dependency artifacts are split out.

## Primary sources

- [Nixpkgs reference manual](https://nixos.org/manual/nixpkgs/stable/)
- [Nix best practices](https://nix.dev/guides/best-practices.html)
- [Import from derivation](https://nix.dev/manual/nix/2.34/language/import-from-derivation.html)
- [Packaging existing software](https://nix.dev/tutorials/packaging-existing-software.html)
- [Pinning Nixpkgs](https://nix.dev/tutorials/first-steps/towards-reproducibility-pinning-nixpkgs.html)
