# PLAN

Completed work and historical validation live in [docs/PLAN_LOG.md](docs/PLAN_LOG.md).
Scope boundaries live in [docs/plan_context/follow-ups.md](docs/plan_context/follow-ups.md).

## Deferred pending separate scope

- [ ] Review and document deployed dotfiles staged-dependency hook semantics after its behavioral tests and agentconf regression pass; static lint does not replace clean Nix build evidence.

- [ ] Coordinate the dotfiles build-layout migration and select a CLI plus bundled GUI pilot when implementation scope is established (context: docs/plan_context/follow-ups.md).
- [ ] Recover and reconcile the historical Nix-memory consolidation proposal before presenting any concrete removal decision (context: docs/plan_context/follow-ups.md).

## Recently completed

- [x] How should completed owner questions preserve answers? Answer: Keep a recognizable question and substantive qualified answer on the checked-off line, link longer evidence, and preserve both when archiving; planning-work now requires this (done 2026-10-26 14:40 EDT; delivered in this commit).

- [x] Consolidate Rust/Zig dependency portability, private-source access and Nix staging in writing-nix; remove local-file-source and host-cache repair advice, add global pointer and coordinate hook implementation; full Nix check passed (done 2026-10-23 21:41 EDT).
- [x] Add universal-app-frontend skill with verified GPUI package identities and application evidence, global AGENTS pointer and shared discovery; skill validation and full Nix check passed (done 2026-10-23 19:19 EDT).
- [x] Require nix build in shared build, language, test-isolation and profiling guidance; reconcile global directives and notify current migration owners; local suite and Nix check passed (done 2026-10-23 18:41 EDT).
- [x] Update Mechatron Prime CI guidance for a 30-minute job timeout, infrastructure-agent-approved exceptions and two-worker queue consumption (done 2026-10-23 18:30 EDT).
- [x] Add test-isolation guidance and a Linux read-only filesystem runner; verify write-escape controls locally and in the Nix check, then deliver a scoped adoption handoff to the affected project (done 2026-10-23 18:23 EDT).
- [x] Standardize CLI --about on canonical PF with optional separate VARIANT, actual build-target provenance and migration acceptance cases (done 2026-10-23 15:34 EDT).
- [x] Extend the cross-platform build skill with canonical implementation selection, one build command with independent scope flags, optional VARIANT paths and migration acceptance cases (done 2026-10-23 13:55 EDT).
- [x] Create the shared writing-bend skill with pinned official sources, compiler/kernel/backend checks, mutation controls and an independent forward trial (done 2026-10-21 16:54 EDT; delivered by this commit in writing-bend/SKILL.md).
- [x] Reconcile the October 14 inbox request, archive 42 completed plan entries, preserve deferred scope, and pass plan lint plus the full suite (done 2026-10-21 15:05 EDT).
