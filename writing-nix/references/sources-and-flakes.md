# Sources and flakes

## Git-backed source visibility

A flake resolved from a Git worktree uses the Git source set. Staging is the
boundary that matters for a new file:

| Worktree state | Included in Git-backed flake source? |
|---|---:|
| committed | yes |
| staged new file | yes |
| tracked file with unstaged edits | yes |
| untracked file | no |
| ignored, untracked file | no |

This often appears as `FileNotFound`, `MissingSourceFile`, or a downstream cache
error rather than “untracked file.” A direct language build may pass because it
reads the ordinary worktree.

Use this sequence after adding or renaming a referenced file:

```sh
git status --short
scripts/check-flake-inputs --repo "$root" path/to/new-input
git add -- path/to/new-input
nix flake archive --json .
```

Stage task-owned paths individually. Do not capture unrelated work with
`git add -A`. `nix flake archive --json .` is the direct way to inspect the
resolved source and locked inputs when visibility remains ambiguous.

## `path:` inputs and source filters

An explicit `path:/absolute/tree` input must materialize its outer tree before
filters inside that flake can run. Large ignored build trees can therefore be
copied even when an inner `cleanSource` or file set later excludes them. Prefer
a Git source such as `git+file:///absolute/repository` when Git's tracked set is
the intended boundary, after staging every required new file.

Nix 2.35 made most flake source reads and copies lazy. `path:` and `hg+:` inputs
remain exceptions. Do not generalize a 2.35 performance claim to those input
types.

When a source path's parent directory name should not affect its store path,
give it a stable name:

```nix
src = builtins.path {
  path = ./.;
  name = "project-source";
};
```

Prefer `lib.fileset` for composable source selection. Remember the classifier
semantics: `difference ./. exclusions` includes a future new file unless the
exclusion class catches it. Test filters over representative sets, including a
new file, rather than testing one known path.

## Flake output checks

`nix flake check` evaluates recognized package, app, dev-shell, formatter, and
other output shapes. It realizes only derivations under `checks`. Make build
coverage explicit:

```nix
checks.${system}.package = self.packages.${system}.default;
```

By default, checks cover the current system. Use `nix flake check --all-systems`
when the contract spans all declared systems. Avoid blindly using
`flake-utils.lib.eachDefaultSystem`: Nixpkgs 26.05 was the last release to
support `x86_64-darwin`, so a generic default-system list can outlive the
package set. Enumerate the systems the project actually supports.

Flakes are still an experimental upstream Nix feature as of Nix 2.35. Pin the
Nix implementation/version when depending on details beyond the stable command
surface.

## Assumptions overturned

- “A file in the worktree is available to Nix.” Git-backed flakes exclude new
  untracked paths.
- “Source filters prevent the outer source from being copied.” An explicit
  `path:` source is materialized before its inner filter runs.
- “A successful `nix flake check` built every package output.” It built only
  derivations exposed under `checks`.
- “Nix 2.35's lazy source work fixed every eager copy.” `path:` remains eager.

## Primary sources

- [Working with local files](https://nix.dev/tutorials/working-with-local-files.html)
- [Nix 2.35 release notes](https://nix.dev/manual/nix/2.35/release-notes/rl-2.35.html)
- [`nix flake check`](https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix3-flake-check)
- [Nix best practices](https://nix.dev/guides/best-practices.html)
- [Nixpkgs release notes](https://nixos.org/manual/nixpkgs/stable/release-notes)
