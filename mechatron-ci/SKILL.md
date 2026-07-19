---
name: mechatron-ci
description: Configure or audit a local project for Peter's Thelio-hosted Mechatron Prime Nix CI, including the exact-commit target manifest, GitHub webhook provisioning, dynamic README badge, and live verification. Use when asked to add Mechatron Prime CI, configure the Thelio runner, add or repair its badge, or bring a pmarreck repository onto local CI.
---

# Mechatron Prime CI

Mechatron Prime exists because **Garnix CI shut down on 2026-07-15** — Garnix was
acquired by Shopify and switched everything off, taking the fleet's cloud Nix CI
with it. Peter's Thelio (`mechatron-prime` / `thelio-nixos`) replaced it: a
self-hosted, single-queue Nix build worker that builds signed GitHub `push`
events for every `pmarreck/*` repo — no GitHub Actions, no Garnix config.

Read the canonical human guide before acting:

```text
/home/pmarreck/Code/mechatron-prime/MECHATRON_PRIME_CI.md
```

It is the sole source of the badge Markdown. Copy its fenced snippet exactly;
replace only `REPOSITORY` with the case-preserving GitHub basename. Never invent
or reformat a badge URL.

## Workflow

1. Read the current project's `AGENTS.md`, relevant memories, `flake.nix`, and
   existing test/build scripts. Confirm its GitHub owner is exactly `pmarreck`.
   Do not configure a repository owned by anyone else.
2. Determine real targets with `nix flake show` or the project's documented CI
   contract. Add `.mechatron-prime/targets` with one valid flake attribute per
   line. Permit blank lines and `#` comments only. The target set must be
   intentional: never guess output names or copy a target list from another
   project.
3. Follow the project's TDD and validation rules. Run its full tests and a
   direct Nix evaluation/build for each selected target before committing. Keep
   the manifest in the normal project commit; the worker fetches it from that
   exact pushed SHA.
4. Replace any retired Garnix or static Mechatron claim in the README with the
   canonical dynamic badge. Preserve unrelated badges and README content.
5. Ensure the Thelio hook exists. From Thelio, first run the canonical
   `--all-owner-repos --dry-run` command; run its live form only when the task
   authorizes GitHub webhook changes. Never put the webhook secret in a repo,
   shell argument, log, or chat response.
6. Push `yolo`, `master`, or `main`, then verify the public endpoint
   `/badges/<REPOSITORY>.json` and the README badge. A new badge appears after
   its first accepted build. Verify `PASSING` only after the worker completes;
   do not describe `BUILDING` as green.

## Boundaries

- Mechatron accepts only HMAC-signed pushes to `yolo`, `master`, or `main` for
  `pmarreck/*`; it runs one global sequential queue. GitHub's declared default
  branch is retained as signed event telemetry, not an admission constraint.
- Do not edit `/etc/mechatron-prime` policy files or require a host rebuild to
  add a project. The per-repo manifest is the self-service control plane.
- Do not expose `/ops/` or private host data in a badge/readme link.
- If selected targets lack a reproducible Nix flake, stop and report that gap;
  do not substitute an ad-hoc command as CI evidence.
