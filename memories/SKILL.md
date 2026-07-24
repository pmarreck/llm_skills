---
name: memories
description: Curate, retrieve, migrate, validate, consolidate, or promote durable shared and project memory lessons. Use whenever work involves a shared memory root, a project MEMORIES/ root, memory frontmatter, consolidation, cross-project lesson promotion, or metadata-only recall.
---

# Memory stewardship

Treat memory roots as a small, curated recall index—not a journal. Shared
lessons live in `$HOME/MEMORIES/`; project-only lessons live in
`<project-root>/MEMORIES/`. Never read or write a project’s memories unless
that project is explicitly within the current task scope.

A project's `MEMORIES/` is committed inside that project's own repository and
may become public, so **never put personal or private information** — real
names, contacts, credentials, secrets, health, finances, or other private
circumstances — in a project-scoped memory. Keep such context only in the
private shared root (`$HOME/MEMORIES/`) or a dedicated private context pack.
Project memories hold only the durable technical lesson.

## Required format

Every memory is a regular Markdown file named:

```text
concise durable lesson.frontmatter.md
```

It starts with exactly these three YAML fields, then a closing `---`:

```markdown
---
description: "One searchable sentence stating the durable lesson."
datetime: 2026-07-20T13:00:00Z
tags: [memory, memories, metadata, frontmatter]
---
```

- Store datetimes as timezone-aware ISO 8601. Default to UTC (`Z`) for new and
  migrated records; honor a different timezone-aware convention only when
  local instructions explicitly require one.
- Keep recalled metadata unchanged and deterministic. Convert timestamps to a
  reader's local timezone only as an explicit presentation step, never as a
  silent read-time rewrite.
- Preserve a legacy file’s creation instant when migrating it; use the current
  instant only for genuinely new lessons.
- Write a concise, specific description. Tags are lowercase hyphenated terms.
  Include the canonical term and useful lexical aliases (`nix`, `nixos`,
  `flakes`; `wasm`, `webassembly`; `i18n`, `l10n`, `localization`). Prefer
  enough aliases for direct metadata searches; do not create a semantic index.
- Keep the body for the evidence, decision, and exact details needed later.
  Do not repeat the filename merely as a heading.

## Recall and validation

List both the shared and current-project indexes in one deterministic,
scope-labeled pass. The default reads filenames only; pass a project root when
the working directory is not the project you mean:

```bash
memories/scripts/list-titles
memories/scripts/list-titles ~/Code/PROJECT
```

For metadata-only selection, add `--headers`; this delegates to the frontmatter
validator and still does not load bodies:

```bash
memories/scripts/list-titles --headers ~/Code/PROJECT
```

Both modes ignore generated `.codescan/` search-index directories in shared
and project memory roots.

The helper is also sourceable as the Bash function `list_memory_titles`.

Read a body only after its filename or frontmatter makes it relevant. Validate
every affected root after an edit or migration:

```bash
memories/scripts/check-frontmatter "$HOME/MEMORIES" ~/Code/PROJECT/MEMORIES
```

The checker rejects old filenames, missing fields, `date` in place of
`datetime`, and datetimes without a timezone offset.

For a reviewed legacy migration, create a recoverable backup, inspect the
metadata-only preview, then apply and re-check:

```bash
memories/scripts/migrate-legacy --dry-run "$HOME/MEMORIES"
memories/scripts/migrate-legacy --apply "$HOME/MEMORIES"
memories/scripts/check-frontmatter "$HOME/MEMORIES"
```

## Write and consolidate

Before handoff, commit, push, ship, or publish, check whether a genuinely new
durable lesson exists. Record it in the narrowest correct scope, or explicitly
state that none applied.

On an explicit consolidation request:

1. Read `~/.local/state/evolving-knowledge-base/state.json` first. Skip roots
   with no changes since their recorded `last_consolidated_at`.
2. Audit changed roots separately by filename and frontmatter, then load only
   potentially overlapping bodies.
3. Merge overlapping or superseded lessons only with a recoverable backup.
   Promote a lesson to shared scope when it genuinely applies to two or more
   projects; leave a project-specific version when it retains essential local
   detail.
4. Record the completed timestamp and roots in the maintenance-state file.

Never bulk-load unrelated bodies or append routine activity to legacy
`MEMORIES.md`, `LEARNINGS.md`, `MISTAKES.md`, or `DESIRES.md` files.
