# Mechatron Prime CI

Thelio builds signed GitHub `push` events on `yolo`, `master`, or `main` for
every `pmarreck/*` repository. The configured policy is two workers consuming
the shared queue; no GitHub Actions or Garnix configuration is needed.

## Job execution limits and capacity

Owner policy, 2026-10-23: build/CI jobs time out after 30 minutes of execution.
Exceeding that limit requires explicit permission from the mechatron-prime
agent, with the project/job, requested bound and reason recorded. Do not remove
or increase the timeout, or split/retry jobs to evade it. Report queue waiting
separately from execution.

Two workers allow another job to progress while one is slow or stuck before its
timeout. Existing CPU/memory limits still apply. Confirm actual deployment and
enforcement with the infrastructure owner; this policy text alone does not
establish that the host has activated the changes.

The previously audited fleet keeps its root-owned target fallback during this
migration. A committed manifest always wins; every new project needs one.

## Standing onboarding approval

As of 2026-10-11, SCS (Senior Cyber/Construct Swarmlord) pre-approves Mechatron Prime
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

2. Provision its GitHub webhook from Thelio. This is a local `mechatron-ci`
   command, not an `/ops` action, and the webhook secret never appears on argv:

   ```bash
   mechatron-ci provision --project REPOSITORY --dry-run
   mechatron-ci provision --project REPOSITORY
   ```

   `--project` may be `nix_ex` or `pmarreck/nix_ex`. If omitted, an owned GitHub
   origin is used. Dry-run first, then provision under the standing approval
   above. Both forms use the local credential-isolated service, with no sudo
   or client-side access to signing or GitHub credentials. `--json` returns a
   structured result. There is no fallback that reads secrets in the client.

   The service accepts one repository per request, validates its owner against
   GitHub's returned metadata, and uses only the configured CI endpoint. Bulk
   discovery remains available to administrators through the underlying
   `provision-mechatron-webhooks --all-owner-repos` tool, not through the socket.

   If an older installed CLI rejects `provision`, use the source checkout
   until its package is updated:

   ```bash
   "$HOME/Code/mechatron-prime/scripts/mechatron-ci" provision --project REPOSITORY --dry-run
   "$HOME/Code/mechatron-prime/scripts/mechatron-ci" provision --project REPOSITORY
   ```

   The ops Services tab shows the provisioner and its most recent operation,
   result, and timestamps. Status is sanitized; credentials and raw GitHub
   errors are never displayed. A failed or disconnected request can be retried:
   each request starts with a fresh hook preflight. GitHub hides existing hook
   signing secrets, so an existing hook's secret relies on its provisioning
   provenance; a hook-list response alone cannot verify signature delivery.

3. Push `yolo`, `master`, or `main`. Its first accepted build creates the badge
   JSON.

## README badge

Replace only `REPOSITORY` with the case-preserving GitHub repository basename.

```markdown
[![Mechatron Prime CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fthelio-nixos.tail66c90.ts.net%2Fbadges%2FREPOSITORY.json&style=for-the-badge)](https://thelio-nixos.tail66c90.ts.net/mechatron-prime/)
```

The image is dynamic (`BUILDING`, `PASSING`, or `FAILING`); its click target is
the shared public Mechatron Prime explanation page.
