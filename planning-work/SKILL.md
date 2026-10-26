---
name: planning-work
description: Keep a project's PLAN.md a short list of one-line checkboxes. Use when adding, completing, reorganizing or migrating PLAN.md items, when PLAN.md holds prose, wrapped items, design notes or a pile of completed items, or before a handoff or commit that touches PLAN.md. Its scripts unwrap items, retire completed ones to docs/PLAN_LOG.md, and lint the format.
---

# Planning work

PLAN.md answers one question: what is left to do, in order? It stays small
enough to read in full at the start of every session. Everything else moves
somewhere with its own purpose.

Scope: apply this to the planning work you were asked to do. Do not migrate
other projects' plans unrequested. Where a project already has a canonical
home for any of the kinds below (a plan kept elsewhere, an Obsidian or business
plan, an existing ADR or context directory), use that home instead of creating
a competing one; the table names the default only.

| Content | Home |
|---|---|
| Open work, plus the last few completions for continuity | `PLAN.md` |
| Completed items, retired verbatim with their section path | `docs/PLAN_LOG.md` (append-only) |
| Background, evidence and design notes an open item needs | `docs/plan_context/<topic>.md`, linked from the item |
| Durable lessons that outlive any one item | project `MEMORIES/` (see the `memories` skill) |
| Decisions bound to specific code paths | the project's ADR log, if it keeps one (optional) |
| Purpose, scope and non-goals | `INTENT.md` |

## PLAN.md format

- A `# PLAN` title and a short preamble before the first `##` section (lint
  default: at most 5 lines), for example pointers to the log and the context
  directory.
- Section headings ordered by priority. Lint accepts headings of any level.
- Each item is exactly one line: `- [ ] text` or `- [x] text`. Nested
  checkboxes are indented (one tab per level is the convention; lint accepts
  any deeper indentation).
- No prose paragraphs, plain bullets, block quotes, code fences or
  hard-wrapped continuation lines. When an item needs more than one line of
  explanation, write the explanation in `docs/plan_context/<topic>.md` and end
  the item with `(context: docs/plan_context/<topic>.md)`.
- When checking an item off, append its completion stamp in the project's
  local time with its zone label, e.g. `(done 2026-09-23 10:15 EDT)`, and the
  commit that delivered it. `plan-retire` ranks recency by the last
  `YYYY-MM-DD [HH:MM]` on the line; an undated completion counts as oldest.
- **Completed questions must carry their answers.** When an item records a
  question from the owner, retain the question (or its recognizable subject)
  and append a concise `Answer: ...` on that same checked-off line. Include the
  actual conclusion and any qualification that changes its meaning. “Answered,”
  “discussed,” a chat reference or a link alone is insufficient. For a long
  answer, keep the useful summary inline and link the detailed explanation or
  evidence in `docs/plan_context/`. The owner must be able to review completed
  questions without searching conversation history. If the question remains
  unresolved or awaits a decision, leave it open and record what is missing;
  do not invent certainty just to close it. Preserve the question, answer and
  detail link together when retiring it to `docs/PLAN_LOG.md`.

Example:

```markdown
- [x] Can the decoder consume stdin? Answer: Yes for sequential input; random-access decoding needs a seekable source (context: docs/plan_context/input-modes.md; done 2026-10-26 14:40 EDT; commit abc1234).
```

## Execute open work continuously

Open PLAN items are standing work to complete as soon as possible, including
overnight, without sacrificing correctness, performance, testing or other project
values. No separate overnight approval is required. A milestone is a checkpoint;
it does not end work when actionable items remain.

Clock, bedtime and wake-time notices are informational context about the owner's
availability. They never imply an agent sleep/wake schedule. Human biological
rest requirements do not suspend actionable agent work.

Before voluntarily ending a turn, review the open items in priority order:

1. If an item needs no owner decision, work on it. If a missing detail is easily
   reversible, choose reasonably, record the assumption and proceed.
2. If an item truly needs the owner's judgment, record the precise question and
   affected dependency; continue independent items. A question on one item is
   not a project-wide stop. Do not request approval already given.
3. Stop when no actionable work remains, every remaining item is genuinely
   blocked, the owner explicitly stops/pauses work, or an actual execution or
   resource limit prevents progress. Report the specific blocker or limit and
   checkpoint the next action. Do not describe the owner's absence, bedtime or
   a completed milestone as a blocker.

Explicit holds, budgets and action-specific approval requirements remain in
force. Keep shelved ideas separate from actionable work. A checkbox does not
authorize irreversible external actions or manufacturing new tasks to stay busy.
Guidance cannot restart a terminated client; durable checkpoints support an
existing authorized restart mechanism without pretending a scheduler exists.

## Scripts

All three are LuaJIT, take the plan path as the final argument (default
`PLAN.md`), and print usage with `--help`. They use POSIX calls through the
LuaJIT FFI and support Linux and macOS; native Windows is not supported.
Supported inputs are readable ordinary files, or symlinks to them, with no
concurrent writers. Writes follow symlinks: the link stays and its target is
replaced, keeping the target's permission bits.

- `scripts/plan-unwrap [--check] PLAN.md` joins hard-wrapped continuation lines
  into their list item. `--check` exits 1 when anything is wrapped. Fenced
  blocks and prose are left alone for a human or agent to relocate.
- `scripts/plan-retire [--keep N] [--log PATH] [--date YYYY-MM-DD] PLAN.md`
  moves completed items, with their whole nested subtree (blank separators
  included), to the log (default `docs/PLAN_LOG.md` beside the plan), keeping
  the `N` most recent (default 10). A completed parent with completed children
  is one item. A completed item with an open descendant is reported as blocked
  and stays. Each retired line gains its section path:
  `- [x] [Section › parent item] text`.
  Safety: a log that resolves to the plan itself (same path, alias or symlink)
  is refused before anything is written; hardlinks are not detected. Only a
  log that does not exist starts empty; a log that exists but cannot be read
  stops the run with both files untouched. Every
  write is checked and goes through a unique temporary file and a rename. The
  log is written and synced before the plan is replaced, so a failure never
  drops completed items: before the log lands both files are untouched, and
  after it lands a retry may duplicate entries but never lose them. Exit 1 on
  an I/O failure, 2 on a usage error. Do not run two instances on one plan at
  once; the last rename wins.
- `scripts/plan-lint [--max-bytes N] [--max-done N] [--max-preamble N] PLAN.md`
  exits 1 and prints `file:line: kind: text` for every line that is not a
  heading, preamble, blank or one-line checkbox. It also fails when the
  preamble exceeds `--max-preamble` lines (default 5), the file exceeds
  `--max-bytes` (default 65536), or more than `--max-done` completed items
  (default 10) are retirable. It counts exactly what `plan-retire` can move,
  so `plan-retire --keep N` always satisfies `plan-lint --max-done N`.
  `--classify` prints each line's kind for debugging.

## Routine

1. Complete an item by checking it and stamping it; for an owner question,
   include the answer on the same line before marking it complete.
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
