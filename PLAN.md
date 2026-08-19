# Plan

## Completed — retire Supacode skill (2026-08-19)

- [x] Remove the staged `supacode-cli` skill and its stale dirtree discovery
      metadata now that Supacode is retired; preserve the deletion in Git.
      - Curiosity poke: a deleted skill must not remain advertised through
        README or sideband discovery metadata.
      - Completed 2026-08-19 13:14 EDT. README and PLAN contain no other active
        Supacode discovery entry; the known-green suite covers installation.

## Active — shared `writing-nix` engineering skill (2026-08-19)

- [x] Derive the skill's decision-changing guidance from relevant shared
      memories and current primary Nix/Nixpkgs documentation; separate durable
      rules from version-sensitive advice and Peter-specific host policy.
      - Curiosity poke: a broad Nix encyclopedia would consume context while
        making trigger selection worse, so each retained rule must prevent a
        demonstrated failure or materially improve diagnosis.
      - Include a sourced "surprising behavior" pass: recent changes,
        counterintuitive mechanisms, and platform asymmetries that overturn a
        plausible agent assumption. Since training-corpus membership is not
        observable, use novelty relative to the agent's initial prediction as
        the test and record which assumption each item overturns.
      - Include ecosystem and community history relevant to contributing to
        Nixpkgs: Guix lineage, governance disputes, forks, compatibility, and
        contribution norms. Present this human context as ecosystem “lore.”
        Separate documented events and project positions from inference so the
        skill supplies temporary technical and human context expertise.
      - Compare each active implementation/distribution with upstream Nix:
        advantages, disadvantages, maturity, compatibility boundaries, and
        whether supported side-by-side userspace installation is possible.
      - Completed 2026-08-19 12:59 EDT. Selected private lessons were checked
        against current primary/first-party Nix, Nixpkgs, NixOS, Lix,
        Determinate Nix, Snix, and Guix records.
- [x] Add a failing integration test for the new skill's observable contract,
      including the Git-index visibility trap, pre-build source audit, scoped
      reference routing, and source attribution.
      - Curiosity poke: a wording-presence test can pass while the skill still
        permits an agent to run Nix before checking the index; test the required
        ordering and executable classifier behavior where practical.
      - Completed 2026-08-19 12:59 EDT. The test failed before the skill and
        checker existed, then separately failed for the requested comparison
        and lore contracts before those sections were added.
- [x] Implement the `writing-nix` skill with a compact entrypoint and focused references
      for flake sources, derivation/package construction, diagnosis/system
      operations, and ecosystem/community context; update discoverability
      metadata and repository documentation.
      - Curiosity poke: destructive activation and lockfile changes require
        explicit authorization boundaries even when evaluation/build commands
        are otherwise safe.
      - Completed 2026-08-19 12:59 EDT. Added the skill, read-only input
        classifier, four routed references, interface metadata, and README
        discovery entry.
- [x] Stage every new skill input before the Nix-backed full suite, validate the
      package, run targeted and complete tests, annotate new files with dirtree,
      and commit only this unit while preserving unrelated staged work.
      - Curiosity poke: the skill must dogfood its own central invariant or its
        passing Nix check is meaningless.
      - Completed 2026-08-19 12:59 EDT. The checker first rejected all eight
        untracked inputs, the exact paths were staged, ShellCheck and the skill
        validator passed, the complete suite passed, and `nix flake check -L
        --all-systems` passed all declared systems.
- [x] After the skill is green, audit the incorporated global Nix memories for
      consolidation. Present an exact keep/merge/remove set before altering the
      private memory repo; retain local incident evidence or narrow exceptions,
      and remove only generic lessons fully superseded by the public skill.
      - Curiosity poke: metadata-only recall already avoids body ingestion, so
        deletion must produce a clearer index rather than merely move useful
        provenance out of reach.
      - Completed 2026-08-19 12:59 EDT. The private root remains unchanged;
        the exact recoverable removal/retention proposal will be presented to
        Peter for approval.

## Active — single physical cross-agent skill tree (2026-08-03)

- [x] Empirically test Codex 0.146 user-skill discovery through a directory
  symlink under `$HOME/.agents/skills`, including a real-directory control and
  cleanup of every temporary fixture. Do not move or rewrite either live skill
  installation during this test.
  - Curiosity poke: current documentation may describe a newer discovery root
    while this installed build still loads legacy `$HOME/.codex/skills`, or an
    interactive client may cache discovery differently from the app server.
  Completed 2026-08-03 16:36 EDT. Codex app-server `skills/list` with
  `forceReload=true` discovered the real-directory control, a child skill
  symlink, and both skills when the entire `$HOME/.agents/skills` root was a
  symlink. A fresh-server cleanup check found zero probe skills afterward.
- [x] Compare the zero-copy canonical-tree design against the materialized-copy
  hooks and obtain Peter's direction before migrating live paths.
  Completed 2026-08-03 16:43 EDT. Peter approved the `$HOME/.agents/skills`
  canonical-tree link, live migration, and explicit retirement of the
  copy-and-sync installer plus related Git hooks.
- [x] Replace copy/sync behavior with a tested zero-copy installer that links
  `$HOME/.agents/skills` to this physical repository, archives displaced
  legacy shared copies, preserves Codex system/local-only skills, and is
  idempotent on macOS and Linux.
  - Curiosity poke: the old and new discovery roots are additive, so leaving
    even one managed legacy directory creates a duplicate skill name.
  Completed 2026-08-03 16:53 EDT. The RED migration test failed on every new
  behavior, then passed 13 assertions covering links, spaced paths, foreign
  roots, byte-preserved backups, duplicate retirement, local/system survival,
  hook retirement, idempotence, and the removed `--sync` interface.
- [x] Remove the post-checkout/post-merge sync hooks and local `core.hooksPath`,
  update README/Nix test wiring, migrate the live roots, and compare discovered
  skill sets.
  Completed 2026-08-03 17:00 EDT. Both harness roots resolve to this repo;
  Codex app-server reports the same 19 canonical user-skill paths, with zero
  set differences and zero duplicate names. The legacy Codex copies are in
  `~/.codex/backups/llm-skills-zero-copy.oJX9te`; the pre-migration full-tree
  backup is `~/.codex/backups/skill-root-migration.20260803T1644EDT`.
  Codex's `.system` tree remains active. The private `about-peter` dependency
  was inverted to a real `SKILL.md` after a failing nested-symlink probe and
  ultimately shipped at private HEAD `f8c98df`, whose exact Mechatron check
  passed in 2 seconds.
- [x] Commit and push the public zero-copy migration, independently match
  `origin/yolo`, and verify exact-commit Mechatron Prime CI.
  Completed 2026-08-03 17:02 EDT. Implementation commit `ce590c5` matched
  `origin/yolo` and its exact Mechatron Prime check passed in 6 seconds.

- [x] Retire active Garnix recommendations from every shared skill and make
  `$mechatron-ci` the single source of truth for CI setup, target manifests,
  badges, and live verification.
  - Curiosity poke: historical retirement context belongs in the migration
    skill, but no general workflow should accidentally resurrect Garnix.
  Completed 2026-07-24 12:52 EDT. A repository-level regression gate now
  rejects stale references outside the migration skill; all three affected
  workflows delegate to `$mechatron-ci` and name the exact-commit manifest.
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
