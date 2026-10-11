# Mechatron Prime CI

Thelio builds signed GitHub `push` events on `yolo`, `master`, or `main` for
every `pmarreck/*` repository. Builds are sequential; no GitHub Actions or
Garnix configuration is needed.

The previously audited fleet keeps its root-owned target fallback during this
migration. A committed manifest always wins; every new project needs one.

## Standing onboarding approval

As of 2026-10-11, BDFN (Benevolent Dictator For Now) pre-approves Mechatron Prime
CI onboarding for all current and future `pmarreck/*` GitHub repositories,
including private repositories and forks. Agents may create or repair the
dedicated CI webhook for those repositories without asking for per-project
approval. The receiver and worker already enforce this owner-wide admission
policy; adding a repository requires no host rebuild or repository allowlist.

This approval covers the existing CI endpoint and signed pushes to `yolo`,
`master`, or `main`. Preserve unrelated hooks, repository settings, and
visibility. It does not authorize exposing private source, logs, or cache
artifacts, changing credentials or sudo permissions, or activating a NixOS
configuration. A private repository still needs the worker's separate source
read credential.

Approval does not install hooks automatically. Each project still needs a
webhook and a committed target manifest. Bulk provisioning remains an explicit
operation; it is never a side effect of onboarding one project.

## Per project

1. Commit `.mechatron-prime/targets` with one existing Nix flake attribute per
   line. For example:

   ```text
   packages.x86_64-linux.default
   checks.x86_64-linux.test
   ```

   Use `nix flake show` to choose real attributes. Blank lines and `#` comments
   are allowed. The exact pushed commit supplies this file, so changing targets
   needs only a normal repository commit, not a Thelio rebuild.

2. Provision its GitHub webhook from the CI host. Dry-run first, then provision
   under the standing approval above:

   ```bash
   mechatron-ci provision --project REPOSITORY --dry-run
   mechatron-ci provision --project REPOSITORY
   ```

   Live provision reads the secret via sudo; approval does not bypass credential
   access. If credentials are unavailable, report that blocker rather than
   asking for approval that has already been granted. `--all-owner-repos` is
   explicit and never the default.

   If an older installed CLI rejects `provision`, use the source checkout:

   ```bash
   "$HOME/Code/mechatron-prime/scripts/mechatron-ci" provision --project REPOSITORY --dry-run
   "$HOME/Code/mechatron-prime/scripts/mechatron-ci" provision --project REPOSITORY
   ```

3. Push `yolo`, `master`, or `main`. Its first accepted build creates the badge
   JSON.

## README badge

Replace only `REPOSITORY` with the case-preserving GitHub repository basename.

```markdown
[![Mechatron Prime CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fthelio-nixos.tail66c90.ts.net%2Fbadges%2FREPOSITORY.json&style=for-the-badge)](https://thelio-nixos.tail66c90.ts.net/mechatron-prime/)
```

The image is dynamic (`BUILDING`, `PASSING`, or `FAILING`); its click target is
the shared public Mechatron Prime explanation page.
