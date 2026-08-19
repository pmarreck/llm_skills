---
name: writing-nix
description: Use when authoring, reviewing, packaging, or debugging Nix expressions, flakes, derivations, NixOS or nix-darwin modules, Nixpkgs contributions, or Nix build/check failures. Do not invoke merely because an ordinary command happens to use the nix CLI.
---

# Writing Nix

Produce Nix code whose source closure, dependency roles, checks, and activation
effects are explicit. Supply enough current ecosystem context to contribute
without applying obsolete technical or community assumptions.

## Start with the source boundary

Before `nix build`, `nix develop`, or `nix flake check` after adding, renaming,
or generating a referenced file:

1. Run `git status --short` at the flake's Git root.
2. Identify only the new paths required by the current change.
3. Run `scripts/check-flake-inputs --repo "$root" PATH...` from this skill.
4. If it reports an untracked path, review it and stage that exact path with
   `git add -- PATH`. Never substitute `git add -A` in a dirty worktree.
5. If it reports an ignored path, review the ignore policy before considering
   `git add -f` or changing the flake source design.

The checker reports state and never mutates the index. A Git-backed flake sees
staged files and tracked files with unstaged edits. It does not see untracked
files. This preflight is part of the build, not optional cleanup.

Read [references/sources-and-flakes.md](references/sources-and-flakes.md) for
source filtering, path inputs, flake outputs, or missing-source failures.

## Route by the work being done

- Read
  [references/derivations-and-packaging.md](references/derivations-and-packaging.md)
  for dependency roles, phases, hooks, overrides, cross compilation, and
  package-language dependency caches.
- Read
  [references/diagnostics-and-activation.md](references/diagnostics-and-activation.md)
  for build failures, fixed-output hashes, closure diagnosis, NixOS activation,
  garbage collection, or store inspection.
- Read
  [references/ecosystem-and-community.md](references/ecosystem-and-community.md)
  before contributing to Nixpkgs or Nix itself, choosing among upstream Nix,
  Lix, Determinate Nix, Snix, or Guix, or when ecosystem lore about governance,
  debates, and forks could affect the work.

Read only the references relevant to the task.

## Working sequence

1. Establish the supported Nix/Nixpkgs version and target systems. Treat
   experimental features and release-note behavior as versioned contracts.
2. Separate evaluation, realization, and activation. Test the cheapest layer
   that can falsify the current hypothesis.
3. Keep derivation computation pure. Put network access in declared fetchers
   or fixed-output derivations and pin every external input.
4. Expose intentional packages and checks. `nix flake check` evaluates many
   output types, but it builds only `checks`; alias a package into `checks` if
   the package must be realized by CI.
5. Test every supported system explicitly, including `--all-systems` when
   checking the whole flake.
6. Verify the resulting executable, closure, or activation behavior rather
   than accepting a successful evaluation as proof.

Evaluation and realization are normally reversible diagnostics. Lock-file
updates, profile changes, garbage collection, service actions, and system
activation mutate state. Keep them within Peter's stated scope and preserve a
rollback path.
