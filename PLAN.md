# Plan

- [x] Add an explicit opt-in gate for introducing i18n to an existing
  non-localized project: ask Peter once, record enabled/deferred/declined in
  the project's `RULES.md`, and do not infer consent merely from touching
  user-facing strings.
  - Curiosity poke: the recorded decision must prevent repeated prompts while
    remaining easy to revisit deliberately.
  Completed 2026-07-24 12:20 EDT with a five-assertion policy regression test
  and a recorded `declined` decision in the dotfiles repository.
- [x] Make memory title/header discovery and frontmatter validation prune every `.codescan/` search-index directory, then refresh Codex's materialized copy — completed 2026-07-24 09:29 EDT.
  - Curiosity poke: generated hidden directories must be ignored without accidentally exempting ordinary hidden legacy files from validation.
- [x] Add a cross-agent `capture-collaboration-evidence` skill that proactively
  notices, evaluates, and records artifact-backed cases where Peter/agent
  synthesis beats either starting approach.
  - [x] Prove the installer distributes the skill and its Codex UI metadata.
  - [x] Define broad implicit triggers plus a strict non-boosterish admission
    threshold and global-memory append protocol.
  - [x] Validate the skill, run the complete suite, refresh the installed Codex
    copy, and independently forward-test recognition/rejection behavior.
  - Curiosity poke: a trigger broad enough to catch unprompted cases can become
    noisy; the admission test must reject mere agreement, praise, delegation,
    and unilateral correction.
  Completed 2026-07-23 16:06 EDT. Fresh-agent forward tests admitted the
  host-scheduled Pause synthesis at accepted-design stage and rejected routine
  exact-specification delegation. Implicit invocation is explicit and
  regression-tested.
- [x] Sync the global agent memory root across machines. Collect every
  machine's `~/MEMORIES` (Mac 1 + thelio-nixos 37 + framework-nixos 0 — a
  conflict-free union of 38), commit to a new private repo
  (github.com/pmarreck/personal-memories, branch `yolo`) cloned **directly** as
  `~/MEMORIES` on all three machines (old copies kept as `.bak`, verified no
  memory lost by content-hash). Make the memories skill git-repo-aware — the
  frontmatter checker and title lister prune `.git/` and skip repo scaffolding
  (README/LICENSE/.gitignore) while still flagging legacy noise — and add a
  stewardship rule forbidding personal/private info in project-scoped
  (repo-committed, possibly public) memories. Completed 2026-07-21 20:20 EDT.
  Curiosity poke: a synced memory root is now itself a git repo, so any tool
  that walks it must be VCS-aware.
- [x] Move the private `about-peter` context pack off the retired
  Documents-CloudManaged path into a new private `llm-skills-private` sibling
  repo (github.com/pmarreck/llm-skills-private, branch `yolo`) holding the whole
  `peter_ai_context/` pack + an `about-peter/` wrapper. Repoint the tracked
  `about-peter` symlink, preserve the legacy `peter_ai_context` path via a
  compat symlink, and replicate to thelio-nixos (clone + symlink + Codex
  materialization). Completed 2026-07-21 18:24 EDT. Curiosity poke: the shared
  repo now carries only a symlink into the private sibling — private content
  never lands in `llm_skills`, and machines lacking the private clone degrade
  gracefully.
- [x] Make the Codex installer/`--sync` skip a skill whose `SKILL.md` source
  can't be materialized (dangling/external symlink) with a warning, instead of
  aborting the whole run; proved mechanically with a synthetic
  dangling-symlink skill (retires the fragile `rm`-based fixture that `rm-safe`
  refused). Completed 2026-07-21 17:30 EDT.
- [x] Remove the unused 9-skill Cloudflare suite (agents-sdk, cloudflare,
  cloudflare-email-service, durable-objects, sandbox-sdk, turnstile-spin,
  web-perf, workers-best-practices, wrangler) from the shared repo and both
  machines' Codex copies; annotate every remaining skill dir with a dirtree
  note. Completed 2026-07-21 18:22 EDT.

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
