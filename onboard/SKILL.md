---
name: onboard
description: Reconstruct a dead session's context from its on-disk transcript when the session ended before /handoff could run - the service dropped, the budget ran out, or the terminal died. Use when starting work in a project whose previous session left no HANDOFF document, or when the user asks what the last session was doing.
---

# onboard — reconstruct context from a transcript

The converse of `handoff`.

`handoff` needs the outgoing session alive and funded: it writes from the
agent's own working memory. That covers a planned wind-down and nothing else.
It yields **nothing** when the service goes down mid-session, when the token
budget is exhausted so no further work can be asked of that agent, or when the
terminal dies and takes the session with it.

The substance is not lost. It is on disk in the transcript. `onboard` rebuilds
context from there, in a new session, of possibly a **different** LLM.

## When to invoke

- Starting work in a project with no `HANDOFF-*.md` and no obvious thread.
- The user asks what the previous session was doing, or to pick up where it
  left off.
- A session died and the user wants the work resumed rather than restarted.

**Do not** invoke it to summarise the *current* session. That is what `handoff`
is for, and a live agent's memory beats any transcript.

## Not `claude --resume`

`--resume` replays a transcript into a fresh run of the **same** agent, raw.
`onboard` is cross-agent and distilled: it produces an opinionated,
`handoff`-shaped document. Different tool, different job.

## It is a degraded handoff. Say so.

A live `handoff` knows what the agent was *about to do* and the unstated
judgement behind it. A transcript shows only what was said and done. You will
recover decisions, tool calls, files touched, commits, and the user's own words
verbatim. You will not recover intent that was never typed.

Every document `onboard` produces **must** state that it was reconstructed from
a transcript, name the source sessions and their date range, and mark inferred
intent as inferred. A reconstructed handoff that reads as
authoritative-from-memory is a lie, and the next agent will act on it.

## Procedure

### Step 1 — collect and reduce

```bash
onboard/scripts/collect-claude-context --cwd "$PWD"
```

This selects the sessions worth reading and reduces them. Useful flags:

| flag | effect |
|---|---|
| `--list` | survey candidates (day, reduced size, session id) without content |
| `--session <id>` | pin exactly one session |
| `--min-bytes <n>` | reduced-text floor before walking back a day (default 5000) |
| `--max-days <n>` | how far back the walk may reach (default 7) |
| `--keep-thinking` | retain assistant thinking blocks |

Run `--list` first when the user is vague about which session they mean.

**Selection is day-anchored, not session-anchored.** The most recent session is
very often a trivial two-message one; anchoring there reconstructs nothing. The
collector anchors on the most recent *day* that had conversation, takes
everything from it, then walks backwards a day at a time only while the
accumulated reduced text is under the floor, bounded by calendar distance so a
gap of idle days cannot drag in months-old work.

**Reduction is the whole point.** Measured over 246 live transcripts on
2026-07-31: 356 MB in, 19.9 MB out, 17.9x. Feeding a raw transcript to a
summariser would consume the very context you are trying to seed.

### Step 2 — summarise in a SUBAGENT

Hand the collected text to a **subagent**, never to the main session. The big
read must stay out of the context being seeded; the main session receives only
the finished document.

Instruct the subagent to emit the **`handoff` document skeleton** — PURPOSE &
INTENT (WHY / RECENT GOALS / IMMEDIATE GOALS / ULTIMATE GOAL), Recently
completed, In-flight, Branch provenance, Coming up next. Read
`handoff/SKILL.md` and reuse its skeleton and its Step-4 redaction rules rather
than writing a second set. Two prompts for one document shape is how drift
starts.

Additional instructions specific to reconstruction:

- Label every inference. "The session appears to have been about to X" is
  honest; "next step is X" is not, unless the user or agent said so.
- Quote the user verbatim where intent matters. Their words are the highest-
  signal thing in the transcript and the reducer keeps them intact.
- Prefer the last stated goal over the most-discussed topic. Volume of
  discussion is not priority.
- If the transcript ends mid-task, say what was in flight and what state it was
  left in. An unfinished edit is more urgent than a finished one.

### Step 3 — redact

`onboard` reads **raw** transcripts, which `handoff` never does — it writes from
memory. Apply `handoff`'s Step-4 redaction rules to the output. Cheap
insurance; not a research project.

### Step 4 — present, then offer to persist

Show the document. Offer to write it as `HANDOFF-<timestamp>.md` so the next
session finds it the normal way. Do not write it unasked.

## Tools

| path | what it does |
|---|---|
| `scripts/reduce-claude-transcript` | one `.jsonl` → reduced Markdown |
| `scripts/collect-claude-context` | select sessions for a cwd, reduce, concatenate |

Both take `-h`, `--about`, and `-`/`@stdin`. `ONBOARD_PROJECTS_DIR` overrides
the transcript root (default `~/.claude/projects`).

## Where the data lives

Claude stores one file per session at
`~/.claude/projects/<slug>/<session-uuid>.jsonl`, where `<slug>` is the cwd with
`/` replaced by `-`. That gives the cwd → sessions mapping for free.

Two traps, both found by running against the real corpus:

1. **A `user` record is not the same as a human turn.** Skill bodies arrive as
   user records holding an array of *text* blocks, and many genuine turns are
   plain strings, so "array content means tool result" is wrong on both edges.
   The reliable discriminator is `promptSource ∈ {typed, queued}` — on one
   session, 49 human turns out of 662 user records. `promptSource == "system"`
   is an injected notification: kept, but labelled `SYSTEM`, never as something
   the user said.
2. **`~/.claude/projects` holds non-transcripts.** `subagents/workflows/*/
   journal.jsonl` contains `{started,result}` records. The reducer rejects those
   as "not a session transcript" *before* the schema-drift check, so nobody goes
   hunting a format change that never happened.

## Schema drift is expected, and must fail loudly

Both tools' record classifiers will go stale as Claude Code changes. An
unrecognised record type is a **hard error**, never a silent skip: a filter that
quietly drops what it does not recognise turns a schema change into data loss
that looks exactly like a quiet session.

When the reducer refuses with `unknown record type(s)`, that is the design
working. Inspect the type, decide whether it carries content, and add it to
`KEEP_TYPES` or `DROP_TYPES` in `scripts/reduce-claude-transcript`. Six types
were found this way on the first real-corpus run — one of them, `pr-link`,
turned out to carry real provenance worth keeping.

Re-derive the schema from **live transcripts**, never from a stale snapshot of
Claude Code's source. The installed tool's current output is ground truth; a
months-old copy is not.

## Not yet built

**Codex support.** `~/.codex/sessions/**/<session>.jsonl` with an index at
`~/.codex/session_index.jsonl`. The index carries `id`, `thread_name` and
`updated_at` but **no cwd**, so the cwd → session mapping has to come from the
`session_meta` record inside each session file. Record types observed:
`event_msg`, `response_item`, `turn_context`, `session_meta`; `response_item`
carries the conversation. Until that reducer exists, `onboard` is Claude-only —
say so rather than silently returning nothing for a Codex session.

## Anti-patterns

- **Presenting a reconstruction as a memory.** State the provenance every time.
- **Reading the raw transcript into the main session.** That defeats the tool.
- **Inventing "coming up next".** If the transcript does not say, write that it
  does not say, and ask the user.
- **Widening `--max-days` to fill a thin document.** A thin transcript means
  thin context. Say so; do not pad it with unrelated older work.
