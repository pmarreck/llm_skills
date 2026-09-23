---
name: planning-work
description: Keep a project's PLAN.md a short list of one-line checkboxes. Use when adding, completing, reorganizing or migrating PLAN.md items, when PLAN.md holds prose, wrapped items, design notes or a pile of completed items, or before a handoff or commit that touches PLAN.md. Its scripts unwrap items, retire completed ones to docs/PLAN_LOG.md, and lint the format.
---

# Planning work

PLAN.md answers one question: what is left to do, in order? It stays small
enough to read in full at the start of every session. Everything else moves
somewhere with its own purpose.

| Content | Home |
|---|---|
| Open work, plus the last few completions for continuity | `PLAN.md` |
| Completed items, retired verbatim with their section path | `docs/PLAN_LOG.md` (append-only) |
| Background, evidence and design notes an open item needs | `docs/plan_context/<topic>.md`, linked from the item |
| Durable lessons that outlive any one item | project `MEMORIES/` (see the `memories` skill) |
| Decisions bound to specific code paths | the project's ADR log |
| Purpose, scope and non-goals | `INTENT.md` |

## PLAN.md format

- A `# PLAN` title and at most a few preamble lines (for example, pointers to
  the log and the context directory).
- `##` section headings, ordered by priority. `###` subsections are allowed.
- Each item is exactly one line: `- [ ] text` or `- [x] text`. Nested
  checkboxes are indented one tab.
- No prose paragraphs, plain bullets, block quotes, code fences or
  hard-wrapped continuation lines. When an item needs more than one line of
  explanation, write the explanation in `docs/plan_context/<topic>.md` and end
  the item with `(context: docs/plan_context/<topic>.md)`.
- When checking an item off, append its completion stamp in the project's
  local time with its zone label, e.g. `(done 2026-09-23 10:15 EDT)`, and the
  commit that delivered it. `plan-retire` ranks recency by the last
  `YYYY-MM-DD [HH:MM]` on the line; an undated completion counts as oldest.

## Scripts

All three are LuaJIT, take the plan path as the final argument (default
`PLAN.md`), and print usage with `--help`.

- `scripts/plan-unwrap [--check] PLAN.md` joins hard-wrapped continuation lines
  into their list item. `--check` exits 1 when anything is wrapped. Fenced
  blocks and prose are left alone for a human or agent to relocate.
- `scripts/plan-retire [--keep N] [--log PATH] [--date YYYY-MM-DD] PLAN.md`
  moves completed items, with their nested blocks, to the log (default
  `docs/PLAN_LOG.md` beside the plan), keeping the `N` most recent (default
  10). A completed item with an open descendant is reported as blocked and
  stays. Each retired line gains its section path:
  `- [x] [Section › parent item] text`.
- `scripts/plan-lint [--max-bytes N] [--max-done N] PLAN.md` exits 1 and prints
  `file:line: kind: text` for every line that is not a heading, preamble,
  blank or one-line checkbox. It also fails when the file exceeds
  `--max-bytes` (default 65536) or holds more than `--max-done` completed items
  (default 10). `--classify` prints each line's kind for debugging.

## Routine

1. Complete an item by checking it and stamping it.
2. Before committing a PLAN.md change, run `plan-retire` and then `plan-lint`.
   Commit PLAN.md and `docs/PLAN_LOG.md` together.
3. If lint reports prose or a design note, move it to `docs/plan_context/`,
   `MEMORIES/` or the ADR log according to the table above. Do not delete it
   and do not fold it into a giant single line.

## Migrating a legacy PLAN.md

1. Commit or otherwise back up the current state first; migration rewrites the
   file.
2. Run `plan-unwrap` so each item is one line.
3. Run `plan-retire --keep 10` to archive completed items.
4. Run `plan-lint` and relocate each remaining violation: context and essays
   to `docs/plan_context/`, lessons to `MEMORIES/`, completed narrative to the
   log. Condense any open item whose line became a paragraph into a one-line
   task plus a context link.
5. Update pointers in other documents (READMEs, documentation guides, code
   comments) that referred to moved sections.

## Control

`plan-lint` is the mechanical check. A project can call it from its test suite
or a pre-commit hook to make the format blocking. It checks shape, not
content: it cannot tell whether an item is still relevant. That judgment stays
with the person or agent maintaining the plan.
