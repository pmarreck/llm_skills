# `onboard` — reconstruct session context from transcripts (design; not built)

**Status:** SPEC ONLY. Deliberately NOT placed at `onboard/SKILL.md` yet — a
skill that exists but is unimplemented would appear in the skill list and get
invoked, which is worse than not existing. Move it there when built.

**Origin:** Peter, 2026-07-30. The converse of `handoff`.

---

## 1. The gap this fills

`handoff` requires the **outgoing** session to be alive and funded. It writes
from the agent's own working memory. That covers the planned wind-down.

It does not cover the case that actually keeps happening:

- the service goes down mid-session (Peter, 2026-07-30: *"Claude was down for
  over 2 hours yesterday. This is a weekly occurrence."*), or
- the token budget is exhausted, so no further work — including `/handoff` —
  can be requested of that agent.

In both, `handoff` yields **nothing**, because you cannot ask a dead session to
summarize itself. The session's substance is not lost, though: it is on disk in
the transcript. `onboard` reconstructs the context **from the transcript, in a
new session**, of possibly a **different** LLM.

Naming: `onboard`, not `handon` (which is just weird).

### Not the same as `claude --resume`

`--resume`/`--continue` replays a transcript into a fresh run of the **same**
agent, raw. `onboard` is **cross-agent** (Claude ⇄ Codex) and **distilled** — it
produces an opinionated `handoff`-shaped document, not a replay. Different tool,
different job.

### It is a degraded handoff, and that is fine

A live `handoff` knows what the agent was *about to do* and the unstated
judgment behind it. A transcript only shows what was said and done. Expect to
recover most of it — decisions, tool calls, files touched, and the user's own
words are all in there — but not all. **Belt-and-suspenders for the case where
the alternative is zero**, not a replacement for `handoff`.

## 2. Where the data actually lives (verified 2026-07-30, this machine)

### Claude

```
~/.claude/projects/<slug>/<session-uuid>.jsonl
```

- `<slug>` = the cwd with `/` replaced by `-` → `/home/pmarreck/Code` becomes
  `-home-pmarreck-Code`. **This gives cwd→session mapping for free.**
- 73 project dirs present.
- **Scale warning, measured:** one active session was **4.9 MB**.

Record `type` values observed in a single session, with counts — note how much
is pure harness bookkeeping:

| type | count | keep? |
|---|---|---|
| `assistant` | 1060 | **yes** (text; tool *names*, not payloads) |
| `user` | 476 | **yes** (real turns) / **no** (tool results) |
| `attachment` | 359 | no — injected file/system content |
| `mode` | 131 | no |
| `ai-title` | 131 | no |
| `last-prompt` | 130 | no |
| `queue-operation` | 110 | no |
| `system` | 76 | mostly no |
| `file-history-snapshot` | — | no |

A `user` record whose `.message.content` is an **array** is a tool-result
carrier, not a human turn — that distinction is the single most important one in
the parser. Those alone were **1.4 MB of the 4.9 MB**.

### Codex

```
~/.codex/sessions/**/<session>.jsonl
~/.codex/session_index.jsonl      # index
~/.codex/history.jsonl
```

Index record shape:

```json
{"id":"019f4994-...","thread_name":"mechatron-prime","updated_at":"2026-07-14T20:51:34Z"}
```

**Gotcha: the index has NO cwd** — only `id`, `thread_name`, `updated_at`. So
Codex's cwd→session mapping must be read from the **`session_meta`** record
inside each session file. Do not assume `thread_name` is the directory; verify
against `session_meta` at implementation time.

Codex record types observed: `event_msg`, `response_item`, `turn_context`,
`session_meta`. `response_item` carries the actual conversation.

## 3. Session selection (Peter's algorithm, 2026-07-30)

Deterministic, and biased toward "the day's work" rather than "the last
session," because the most recent session is often a trivial two-message one.

1. **Agent choice.** Default: whichever agent has the more recent transcript for
   this cwd. `--agent claude|codex` forces it — *"to make it deterministic."*
2. **Anchor on the most recent DAY** on which conversation occurred for this
   cwd (not the most recent session), and take **everything from that day**.
3. **If the reduced text is under a size floor**, walk **backwards day by day**,
   accumulating more sessions from the **same** agent, until either:
   - total reduced size exceeds the size threshold, **or**
   - the span of days exceeds the day threshold.
4. Both thresholds are configurable; the size floor Peter suggested as a
   starting point was ~5 KB of *reduced* text, with sensible caps above.

**Measure the thresholds against REDUCED size, not raw file size.** Raw is
dominated by tool payloads and would defeat the purpose.

Offer `--list` to show candidate sessions (timestamp, first user message
preview, reduced size) and `--session <id>` to pin one explicitly.

## 4. The reducer — this is the actual engineering

**The whole design rests on one rule: the ndjson→text step is a REDUCTION, not
a transcription.** Feeding 4.9 MB to a summarizing subagent blows the very
context you are trying to seed. Target roughly **1–2 orders of magnitude**
smaller.

Deterministic, no LLM in this stage:

**Keep**
- **Every human turn, verbatim.** These are the highest-signal records in the
  file and the cheapest — Peter's own words are what state intent.
- Assistant **prose** (conclusions, findings, reasoning) — not raw tool blobs.
- Tool **invocations reduced to a line**: tool name, the target path/command,
  and a short outcome (`ok` / exit code / first line of error). Not the payload.
- File paths touched, and commits/SHAs mentioned.
- Timestamps at turn granularity.

**Drop**
- All bookkeeping types (`mode`, `ai-title`, `last-prompt`, `queue-operation`,
  `file-history-snapshot`, `attachment`).
- Tool **result payloads** — file contents, command stdout, search output.
  Truncate to first N lines with an elision marker.
- Injected system reminders and CLAUDE.md/AGENTS.md content (it is already
  loaded in the new session; re-injecting wastes context).
- Thinking blocks (optional flag to keep).

**Output:** a plain Markdown transcript, chronological, speaker-labelled. Human
readable on its own — useful even without the summarization step.

**This reducer is reusable beyond `onboard`**, which improves its EV: `handoff`
can cross-check "what the transcript says happened" against "what I remember,"
and it is the same parser the 2026-07-29 claude-mem mining had to write ad hoc.

## 5. Summarization — in a subagent, using `handoff`'s prompt

Feed the reduced text to a **subagent** of the *new* LLM and have it emit a
document in `handoff`'s existing skeleton (PURPOSE & INTENT / WHY / RECENT GOALS
/ IMMEDIATE GOALS / ULTIMATE GOAL / Recently completed / In-flight / Branch
provenance / Coming up next).

**Subagent, not the main session** — same context-hygiene reason the claude-mem
mining used one on 2026-07-29: the big read stays out of the session being
seeded. The main session receives only the finished document.

Reuse `handoff`'s prompt text rather than writing a second one, so both tools
produce the same shape and drift cannot open between them.

**Provenance honesty:** the output MUST state it was reconstructed from a
transcript, name the source sessions and date range, and flag that
"about-to-do" intent is inferred rather than stated. A reconstructed handoff
that reads as authoritative-from-memory is a lie.

## 6. Format drift

Both schemas will change across tool versions. Peter, 2026-07-30: *"I'm fine
with dealing with format drift — tests on actual-recent conversations cover
it."*

Per the standing rule that filters are tested as **classifiers over sets**:

- Corpus of **real** recent transcripts from both agents.
- **Sensitivity:** every human turn in the sample is present in the output.
- **Specificity:** no bookkeeping record type leaks through; no tool payload
  exceeds the truncation bound.
- **Reduction ratio floor:** assert the output is ≥N× smaller than input — a
  silent regression to near-transcription is the failure that matters.
- **Fail loudly on unknown record types** rather than skipping them silently: an
  unrecognized `type` is exactly how a format change becomes silent data loss.

## 7. Redaction

Peter, 2026-07-30: *"We already rewrote those logs. Shit happens."* — the
specific 2026-07-28 sudo-password incident is handled, so do not over-engineer.

Still worth a cheap generic pass, because `onboard` reads **raw** transcripts
and pipes them to a subagent, whereas `handoff` writes from memory and never
touches the raw log. Reuse `handoff`'s existing Step-4 redaction rules rather
than inventing new ones. Cheap insurance, not a research project.

## 8. On the leaked Claude Code source

A leaked copy exists in a sibling repo. Peter's actual interest was its
**.jsonl conversation-parsing/transforming code** — i.e. the schema knowledge —
**not** its compaction/summarization algorithm. (An earlier draft of this spec
misread the ask and objected to the wrong thing.)

**Not needed, and the live data is the better source.** The entire schema in §2
was derived empirically from Peter's own transcripts in about two commands:
record-type inventory with counts, the `user`-record-with-array-content =
tool-result distinction, the `/`→`-` slug mapping, and the Codex
missing-cwd gotcha.

The decisive argument is §6, not provenance: the leak is **months stale**, while
the on-disk transcripts are ground truth for the format the installed tools emit
**today**. Since this whole design has to survive format drift, deriving the
parser from live transcripts — and testing it against a rolling corpus of recent
ones — is *more correct*, not merely tidier. If the schema ever becomes unclear,
re-derive from fresh transcripts rather than consulting a snapshot that is
already out of date.

## 9. Build order (each step independently useful)

1. **Claude reducer** + tests. Useful immediately as a standalone
   "show me what happened in that session" tool.
2. **Session selection** (§3) with `--list` / `--agent` / `--session`.
3. **Subagent summarization** wired to `handoff`'s skeleton.
4. **Codex reducer** (needs the `session_meta` cwd investigation).
5. Promote to `onboard/SKILL.md`.

Implementation language: Bash is likely to get unwieldy parsing two ndjson
schemas — **LuaJIT** per the standing "Bash that gets unwieldy should be ported
to LuaJIT" rule, or Zig if it wants to be fast over 73 project dirs. `jq` is
sufficient for a first cut.
