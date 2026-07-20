---
name: memories
description: Curate, retrieve, migrate, validate, consolidate, or promote Peter's durable shared and project memory lessons. Use whenever work involves ~/MEMORIES, any project MEMORIES/ root, memory frontmatter, weekly consolidation, cross-project lesson promotion, or metadata-only memory search.
---

# Memory stewardship

Treat memory roots as a small, curated recall index—not a journal. Shared
lessons live in `~/MEMORIES/`; project-only lessons live in
`<project-root>/MEMORIES/`. Never read or write another project’s memories
unless Peter has placed that project in scope.

## Required format

Every memory is a regular Markdown file named:

```text
concise durable lesson.frontmatter.md
```

It starts with exactly these three YAML fields, then a closing `---`:

```markdown
---
description: "One searchable sentence stating the durable lesson."
datetime: 2026-07-20T09:00:00-04:00 # America/New_York (EDT)
tags: [memory, memories, metadata, frontmatter]
---
```

- Use an ISO 8601 datetime with numeric offset. For Peter’s memories, add the
  `America/New_York` comment and use the actual `EST` or `EDT` abbreviation.
- Preserve a legacy file’s creation datetime when migrating it; use current
  Eastern time only for genuinely new lessons.
- Write a concise, specific description. Tags are lowercase hyphenated terms.
  Include the canonical term and useful lexical aliases (`nix`, `nixos`,
  `flakes`; `wasm`, `webassembly`; `i18n`, `l10n`, `localization`). Prefer
  enough aliases for direct metadata searches; do not create a semantic index.
- Keep the body for the evidence, decision, and exact details needed later.
  Do not repeat the filename merely as a heading.

## Recall and validation

List filenames first. For metadata-only selection, inspect headers without
loading bodies:

```bash
memories/scripts/check-frontmatter --headers ~/MEMORIES
memories/scripts/check-frontmatter --headers ~/Code/PROJECT/MEMORIES
```

Read a body only after its filename or frontmatter makes it relevant. Validate
every affected root after an edit or migration:

```bash
memories/scripts/check-frontmatter ~/MEMORIES ~/Code/PROJECT/MEMORIES
```

The checker rejects old filenames, missing fields, `date` in place of
`datetime`, and datetimes without a timezone offset.

For a reviewed legacy migration, create a recoverable backup, inspect the
metadata-only preview, then apply and re-check:

```bash
memories/scripts/migrate-legacy --dry-run ~/MEMORIES
memories/scripts/migrate-legacy --apply ~/MEMORIES
memories/scripts/check-frontmatter ~/MEMORIES
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
