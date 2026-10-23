---
name: mechatron-ci
description: Configure or audit a local project for Peter's Thelio-hosted Mechatron Prime Nix CI, including the exact-commit target manifest, GitHub webhook provisioning, dynamic README badge, and live verification. Use when asked to add Mechatron Prime CI, configure the Thelio runner, add or repair its badge, or bring a pmarreck repository onto local CI.
---

# Mechatron Prime CI

Mechatron Prime exists because **Garnix CI shut down on 2026-07-15** — Garnix was
acquired by Shopify and switched everything off, taking the fleet's cloud Nix CI
with it. Peter's Thelio (`mechatron-prime` / `thelio-nixos`) replaced it: a
self-hosted Nix build service that builds signed GitHub `push` events for
every `pmarreck/*` repo — no GitHub Actions, no Garnix config.

## Execution budget and worker capacity

Owner policy, 2026-10-23: build/CI jobs have a **30-minute execution timeout**.
A longer run requires explicit permission from the **mechatron-prime agent**
before starting or extending it. Give that agent the project, exact job/commit,
requested bound and reason; record the approved scope. Do not silently increase
a timeout, remove it, or split/retry work merely to evade the limit. Queue waiting
is reported separately from execution time.

The CI service is to run **two workers** against the shared queue so a slow or
stuck job does not consume the only execution slot while awaiting its timeout.
This means two CI jobs can progress, not unlimited nested compilation. Preserve
the existing CPU/memory/resource controls. Verify deployed worker capacity and
timeout enforcement with the infrastructure owner before claiming they are live;
this policy update is not evidence of service activation.

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
5. Ensure the Thelio hook exists. From Thelio only (not via `/ops`):

   ```bash
   mechatron-ci provision --project REPOSITORY --dry-run
   mechatron-ci provision --project REPOSITORY
   ```

   The canonical guide records standing approval for dedicated Mechatron Prime
   CI webhooks on all current and future `pmarreck/*` repositories, including
   private repositories and forks. Do not ask for per-project approval again.
   Preserve unrelated hooks and settings, and follow the guide's credential
   and privacy boundaries. If the installed CLI rejects `provision`, use the
   source-script fallback documented there. The local Unix-socket broker holds
   the credentials; project agents need neither sudo nor secret-file access.
   `--json` returns the sanitized result. A missing/unavailable broker is an
   infrastructure blocker, not a reason to ask for redundant project approval.
   Never put the webhook secret in a repo, shell argument, log, or chat response.
   The ops Services tab reports the provisioner's state and most recent request.
   Bulk provisioning remains a separate administrator-only helper operation.
6. Push `yolo`, `master`, or `main`, then verify the public endpoint
   `/badges/<REPOSITORY>.json` and the README badge. A new badge appears after
   its first accepted build. Verify `PASSING` only after the worker completes;
   do not describe `BUILDING` as green.
7. Give the project agent a self-service verification command. On any
   Nix-capable tailnet machine with the `mechatron-ci` package installed, use:

   ```bash
   mechatron-ci queue --project REPOSITORY --commit SHA_PREFIX --json
   mechatron-ci log --project REPOSITORY --commit SHA_PREFIX --json
   ```

   Inspect active jobs across both workers separately from claimed work
   and the FIFO waiting queue; the queue API includes enqueue/start timestamps and elapsed
   seconds. `log` reports recent completed outcomes with their terminal run
   duration. `FAIL` + `nix-build` is a test/build failure. `TIMEOUT` +
   `github-timeout` is a GitHub brownout after retries; do not debug the
   project's tests for that outcome. An execution-budget timeout is different:
   inspect the recorded stage/reason and seek an approved exception only when
   warranted. `STOPPED` is an operator interrupt, OOM, or hang bound that
   is not a GitHub blip. `SHA_PREFIX` is 7–40 hexadecimal characters. Prefer the
   JSON form for agents; it is a private Tailscale operations API, never a
   README link.

## Boundaries

- Mechatron accepts only HMAC-signed pushes to `yolo`, `master`, or `main` for
  `pmarreck/*`; two workers consume the shared queue under the policy above.
  GitHub's declared default
  branch is retained as signed event telemetry, not an admission constraint.
- Do not edit `/etc/mechatron-prime` policy files or require a host rebuild to
  add a project. The per-repo manifest is the self-service control plane.
- Do not expose `/ops/` or private host data in a badge/readme link.
- If selected targets lack a reproducible Nix flake, stop and report that gap;
  do not substitute an ad-hoc command as CI evidence.
