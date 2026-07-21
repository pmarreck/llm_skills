# Plan

- [x] Depersonalize the public `memories` skill while preserving local owner
  conventions as ordinary shared memories.
  - [x] Reject names, handles, locations, and owner-specific timezones across
    the skill and its integration tests.
  - [x] Make legacy migration emit portable timezone-aware UTC metadata by
    default while continuing to preserve retained Markdown bodies exactly.
  - [x] Refresh the installed Codex copy and run the complete suite without
    involving Mechatron Prime.
  - Curiosity poke: can a local memory override a generic default without
    turning the public skill back into a hidden per-user policy bundle?
  Completed 2026-07-21 10:16 EDT. The public default is UTC, raw recall remains
  lossless, and owner-specific Eastern-time behavior now lives only in a
  private shared memory override.

- [x] Add a one-command, sourceable shared/project memory title and header
  browser, then refresh Codex's materialized copy. Completed 2026-07-20 21:52
  EDT with deterministic set classification, header-validation delegation,
  no-glob/Git-less proofs, complete suite, and byte-identical installed copy.
  Curiosity poke: it must work unchanged in Peter's no-glob interactive shell
  and outside Git worktrees.
- [x] Prove the memory migration preserves every retained Markdown body byte-for-byte, then repair its extra-blank-line defect. Completed 2026-07-20 09:35 EDT.
- [x] Refresh Codex's materialized memories skill after the body-preservation repair, retaining a recoverable prior copy. Completed 2026-07-20 09:41 EDT.
- [x] Add the shared memory-frontmatter skill and its mechanically checked metadata contract. Completed 2026-07-20 09:33 EDT.
- [x] Materialize the validated new shared skill in Codex without refreshing the unrelated i18n edit. Completed 2026-07-20 09:36 EDT.
- [x] Add a regression check for the shared Mechatron skill and local-only Codex bundle exclusion (2026-07-19 09:17 EDT).
- [x] Add `mechatron-ci` to the shared skill repository and ignore `.system/` (2026-07-19 09:17 EDT).
- [x] Preserve Codex's local Mechatron directory, then install a real materialized copy; validate both consumers' paths (2026-07-19 09:18 EDT). Curiosity poke: Codex skips symlinked skill folders.
- [x] Add macOS/Linux integration coverage for opt-in hook-driven Codex sync (2026-07-19 09:31 EDT). It preserves local-only skills and declares its hook location.
- [x] Implement portable staged `--codex --sync` and tracked post-checkout/post-merge hooks (2026-07-19 09:33 EDT).
- [x] Enable the repository-local hook, validate the real installation, document it, and commit the verified change (2026-07-19 09:34 EDT).
