# Diagnostics and activation

## Locate the failing layer

Classify the failure before changing code:

1. **Evaluation:** syntax, missing attributes, unsupported systems, IFD, source
   visibility, or module merge errors.
2. **Realization:** fetch, sandbox, compile, test, install, or closure failures.
3. **Activation:** service restarts, bootloader changes, migrations, mount
   changes, or session interruption.

Useful discriminators:

```sh
nix flake check --no-build --all-systems
nix build -L .#attribute
nix log .#attribute
nix derivation show .#attribute
nix print-dev-env .#devShell
nix path-info -S .#attribute
nix why-depends .#attribute /nix/store/exact-dependency
```

`nix why-depends` follows runtime references and reports the shortest closure
path. Add `--derivation` when the question concerns build-time dependencies.

## Fixed-output derivations

Use a fake hash to discover a new fixed-output hash only after proving the
intended fetched content changed. An empty output or empty-tree hash can mean
the builder could not reach the network, certificates, or remote. First inspect
the fetch log and test network access from the actual builder.

A stale `result` or `result-*` symlink is separate from a source/hash problem.
Rebuild the exact output and inspect the new result path.

## Store and closure safety

Never recursively search or measure all of `/nix/store` with `rg`, `find`, or
`du`. The path count and metadata I/O can saturate storage. Resolve an exact
store path using `nix path-info`, `nix derivation show`, or a package output,
then inspect that bounded path.

Use `nix store gc --dry-run` on Nix 2.34 or later before garbage collection.
Garbage collection and profile deletion are mutations; confirm roots and
recoverability first.

## NixOS activation gate

Whole-system activation can change unrelated services even when the requested
edit is small. Before `switch`:

1. Build the exact host output without activating it.
2. Compare the candidate flake-lock revision with the running system's
   revision. Do not silently deploy unrelated lock movement.
3. Run `nixos-rebuild dry-activate --flake PATH#HOST` and inspect every listed
   restart, reload, and stop.
4. Compare closures when the change is unexpectedly large.
5. State likely session interruption or reboot requirements and preserve the
   previous generation as the rollback target.
6. Activate only within explicit authorization.

NixOS 26.05 introduced switch inhibitors for transitions that cannot safely
activate in place. Do not bypass them with `NIXOS_NO_CHECK=1` without reviewing
the specific inhibitor and obtaining explicit direction. Restarting or
reloading systemd units directly from activation scripts is deprecated, with
removal planned for NixOS 26.11; express service relationships through NixOS
module options instead.

## Assumptions overturned

- “A changed FOD hash proves upstream content differs.” Fetch failure can
  produce an empty output on one builder.
- “A NixOS switch applies only the edited option.” It activates the whole
  evaluated system closure and may include unrelated lock changes.
- “Searching the immutable store is harmless.” A recursive metadata scan can
  make an interactive machine unusable.
- “An activation warning is advisory.” A switch inhibitor may represent an
  unsafe transition that requires a reboot or migration.

## Primary sources

- [Nix command reference](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix.html)
- [`nix why-depends`](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-why-depends)
- [Nix 2.34 release notes](https://nix.dev/manual/nix/2.34/release-notes/rl-2.34)
- [NixOS release notes](https://nixos.org/manual/nixos/unstable/release-notes)
