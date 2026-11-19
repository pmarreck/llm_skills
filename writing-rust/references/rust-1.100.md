# Rust 1.100 upgrade assessment

Verified 2026-11-13. Stable 1.100.0 was released 2026-11-12. This is an
assessment reference, not blanket authorization to change project pins.

## Changes worth checking

The [official release notes](https://doc.rust-lang.org/releases.html#version-11000-2026-11-12)
identify these compatibility concerns:

- Never-type fallback becomes `!` in every edition; `Infallible` becomes its
  alias. Check inference-sensitive generic calls and overlapping implementations.
- Closure capture in `if let` becomes more precise; trait-object compatibility
  checks expand. Diagnose actual compiler errors before changing behavior.
- Generalized allocator implementations on `Box` can require type annotations.
- Cargo changes its intermediate artifact layout. Consume its JSON
  `compiler-artifact` messages instead of guessing internal paths.
- `cargo install` uses packaged lockfiles by default. This does not replace
  Nix-controlled dependency sourcing or the project's build contract.

The [release announcement](https://blog.rust-lang.org/2026/11/12/Rust-1.100.0/)
also describes useful additions: custom allocator support, `DropGuard`, Cargo
unused-dependency diagnostics, and opt-in dependency publication cooldowns.
Unused-dependency diagnostics require enough targets to be built to establish
non-use; they do not cover all development dependencies. Cooldowns are not
retroactive lockfile auditing or a complete supply-chain defense. Consider
these features when they solve an existing need, not as mandatory rewrites.

## Nix-first qualification

1. Recover the current compiler source and exact resolved version for each
   route: native packages, cross packages, development shells and test
   derivations. `Cargo.toml` MSRV is not evidence of the selected compiler.
2. Check whether the pinned Nix compiler provider contains 1.100.0 and the
   required targets. If not, propose a narrow provider-input update. Avoid
   refreshing unrelated inputs or globally installing Rust to bypass the pin.
3. Preserve Cargo.lock unless a specific compatibility problem requires a
   dependency change. A compiler upgrade alone need not raise a library's
   MSRV; using newer APIs does. Test any continuing MSRV claim independently.
4. Build with `nix build`, then run the complete `./test` entry point and its
   configured formatting/lint checks. Treat new diagnostics explicitly; do not
   suppress warnings or weaken tests merely to pass the upgrade.
5. Run existing external ABI consumers and shared cross-implementation vectors
   where relevant. Qualify supported native targets and cross-build routes
   within the project's resource limits. A Linux pass is not a Windows or
   macOS qualification, and a cross-build is not a native execution test.
6. Report the old/new versions, changed pins, measured results and untested
   targets. Preserve existing launch priorities and holds; assess and recommend
   scheduling when an upgrade would displace committed work.

First confirm the unchanged project passes its current checks when practical,
so pre-existing failures are not attributed to the compiler upgrade. Do not
combine a toolchain bump with broad refactoring or opportunistic dependency
updates; those obscure the cause of any regression.
