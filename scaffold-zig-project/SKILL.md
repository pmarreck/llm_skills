---
name: scaffold-zig-project
description: Start a new Zig repository, library, codec, or CLI. Use with writing-zig for greenfield Zig work; this skill coordinates project intent, Nix-first build wiring, test entry points, repository conventions, and the initial plan.
---

# Scaffold a Zig project

This skill owns the greenfield project workflow. The shared
[`writing-zig`](../writing-zig/SKILL.md) skill owns language and API correctness;
read it before generating Zig source or `build.zig`. Treat old snippets from
previous versions as historical examples, not templates.

## Gather only material requirements

Read the applicable global/project `AGENTS.md` and invoke
`gather-project-intentions` if the project has no `INTENT.md` or its purpose is
unclear. Recover decisions already stated before asking the owner.

Confirm or infer from context:

- project/repository name and one-line purpose;
- library, CLI, GUI, or combination, and the canonical implementation if it is
  multi-language;
- supported OS/architectures and any ABI/libc variants;
- public C ABI requirements, including pointer-plus-length byte APIs and
  explicit ownership;
- external dependencies and whether they are public or private sources; and
- what constitutes the minimum meaningful test and packaged runtime check.

Ask only about choices that materially affect architecture, compatibility,
privacy, cost, or verification. Choose reversible details reasonably and
record assumptions.

## Build the smallest complete project skeleton

Use Nix from the beginning. Follow `writing-nix` for the flake and dependency
source model, and `cross-platform-project-build-arch` for target paths,
canonical implementation selection and `./build` flags. Do not scaffold an
optional Nix path or a direct compiler fallback.

Create the files the project actually needs, commonly:

- `INTENT.md` and a short `PLAN.md`;
- `flake.nix` plus its lockfile, using an exact Zig version from the chosen
  Zig source and declaring all build/test dependencies;
- `build.zig` and `build.zig.zon` matching that exact compiler;
- one complete `./test` entry point and thin `./build`, `./run`, and optional
  `./fuzz` entry points;
- `src/` with a pure core and explicit I/O adapters where that boundary helps;
- headers and FFI tests only when a C ABI is part of the product; and
- `.gitignore` entries for Zig/Nix outputs and the project's local indexes.

Use the current approved `AGENTS.md` link convention. The `setup_zig_repo`
shell alias is only a partial legacy bootstrap; consult the shared memory with
that title before relying on it, and inspect every file it creates. Use Git
directly and follow the repository's branch policy. Do not create or publish a
remote unless that is within the owner's request.

## Test the skeleton and leave it usable

Write a failing behavior test before implementing the core. Tests must stay
inside disposable test-owned state; use `test-isolation` for any test that
mutates files, project selectors, publication outputs, or services. Keep the
complete `./test` fast and include all required behavior, CLI, build and
packaged-artifact checks. Run it and the canonical `nix build`; don't report a
scaffold as complete based on generated files alone.

For a Zig library driven by a C `main`, verify libc linkage and the real C ABI
on Linux as well as macOS/Windows targets. Ensure imported module tests are
actually reachable and separately compiled where needed. Smoke-run the
packaged executable on native platforms to catch loader/ABI failures.

Use the `mechatron-ci` skill after real flake outputs exist and have passed
locally; it owns target selection, the `.mechatron-prime/targets` manifest,
badge setup and live CI verification.

## Improve the scaffold from evidence

Templates must compile with the project's pinned compiler and pass the
project's Nix checks. When a repeated Zig or Nix failure exposes a general
scaffolding gap, add a minimal reproduction and version scope to
`writing-zig`, `writing-nix`, or their focused references. Do not restore a
copy-pasted template that contradicts current pinned APIs.
