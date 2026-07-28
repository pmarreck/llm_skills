# Architecture Decision Records — design (not yet built)

**Status:** design only. Peter chose "design now, build later" on 2026-07-28 so
this would not pull a session away from the Mecha Validate / Rotshield revenue
path. Nothing in here is implemented.

**Origin:** Peter, 2026-07-28, after a conversation with John Davenport
(`johns10`) on the Elixir Slack about his `code_my_spec` project.

---

## 1. The problem this exists to solve

**Chesterton's Fence.** An agent — or Peter six weeks later — encounters
something that looks wrong, unnecessary, or over-complicated, and removes it.
The reason it was there is gone: it lived in a conversation that was compacted
away, or in a human's head, or in a commit message nobody thought to read.

The fleet already loses this constantly. Concrete examples from a single day:

- `accentd.nix` has no `wantedBy`. That looks like an oversight. It is the
  entire safety control, and `systemctl disable` is not a substitute for it on
  NixOS. Without the reason recorded, the "fix" is obvious and wrong.
- `sigil`'s CLI is written in C *specifically* so it cannot `@import` the Zig
  core. A reasonable agent "simplifies" that to Zig and silently destroys the
  boundary the whole design rests on.
- `printable-binary -s` and never `-n`, because `-n` preserves literal newlines
  and would break NDJSON's one-record-per-line invariant. `-n` looks like a
  harmless legibility upgrade.

Commit messages carry some of this, but they are keyed to *when a change
happened*, not to *what a future reader is about to touch*. Nobody greps six
months of log before editing a file.

## 2. Prior art, and what is actually new here

Architecture Decision Records are not novel and are not `code_my_spec`'s. The
pattern is **Michael Nygard, 2011, "Documenting Architecture Decisions."** The
classic template is:

    Title / Status / Context / Decision / Consequences

**`code_my_spec` does not contain ADRs.** Checked 2026-07-28 against
`layeddie/code_my_spec` (the Elixir one) and `codemyspec.com`: no decision
records, no ADR files, no mention on the site. It is a spec-driven-development
Claude plugin (`spec-writer` / `code-writer` / `test-writer` agents;
`generate_spec` → `generate_component_test` → `generate_component_code`
commands) plus a Phoenix SaaS. The ADR idea reached Peter through conversation
with John, not through that codebase. Recorded so nobody later goes looking for
a source that isn't there.

**What IS worth taking from `code_my_spec`:** its `hooks.json` wires `Stop` and
`SubagentStop` to `mix cli evaluate-agent-task`. They do not trust the agent to
remember to do the bookkeeping — the harness asks at stop time. That insight
shaped section 5 below, even though Peter chose manual capture.

### The genuinely new field: **Who**

Classic ADRs have no notion of authorship-agency; they assume a human team, so
"who decided" is uninteresting. In an agent-operated fleet it is the single
fastest-decaying and most load-bearing piece of provenance:

| `who` | Meaning | Why a future reader cares |
|---|---|---|
| `peter` | Peter decided; agent executed | Do not re-litigate. Ask before changing. |
| `agent+peter` | Proposed by agent, ratified by Peter | The reasoning is sound but the *authority* is Peter's. |
| `agent` | Agent decided unilaterally | **Lowest trust.** Legitimate to revisit; may encode a misunderstanding no human ever reviewed. |

That gradient is the point. An `agent`-authored fence is a much weaker fence
than a `peter`-authored one, and today nothing in the fleet records the
difference.

## 3. Record schema

One JSON object per line, NDJSON. Append-only.

```json
{
  "id": "adr-20260728T184012-0400-7f3a",
  "when": "2026-07-28T18:40:12-04:00",
  "who": "agent+peter",
  "agent": "claude-opus-5/Einstein",
  "what": "accentd must not auto-start",
  "where": ["system76_thelio_nixos/accentd.nix"],
  "status": "accepted",
  "supersedes": null,
  "evidence": ["commit:c8042cb"],
  "why_pb": "…printable-binary…",
  "alternatives_pb": "…printable-binary…",
  "how_pb": "…printable-binary…"
}
```

### Field rules

- **`when`** — ISO 8601 **with offset**, Eastern (`-04:00` EDT / `-05:00` EST),
  matching the `memories` skill convention. Derive the offset from the record's
  own date; never assume one year-round.
- **`who`** — the three-value enum above. Required. No default: a missing value
  must be an error, because silently defaulting to `agent+peter` would
  manufacture authority the decision never had.
- **`where`** — **repo-relative paths or globs, never prose.** This is the join
  key the retrieval hook matches on. If `where` is a sentence, retrieval cannot
  work and the whole system degrades to a log nobody reads. This is the most
  important constraint in the schema.
- **`status`** — `accepted` | `superseded` | `reversed`. Records are never
  edited or deleted; a reversal is a new record whose `supersedes` names the
  old `id`. The wrong turns are the most instructive part of the history.
- **`evidence`** — commit SHAs, test names, benchmark rows. A decision with no
  evidence is an opinion; say so by leaving this empty rather than inventing.

### Why `_pb` (printable-binary) for prose fields

Fields carrying free text are stored **printable-binary encoded**, with the
`_pb` suffix making the encoding self-describing. Encode with `-s` (preserve
spaces); decode with `-d`.

The convenience argument is that prose keeps its linebreaks, markdown, and
quotes. The **real** argument is correctness: `printable-binary -s` emits no
`"`, no `\`, and no newline, verified over the full byte range. Dropping its
output into a JSON string therefore makes *"agent botched the escaping and
corrupted the log"* **inexpressible** rather than merely unlikely. That is the
same move `sigil` made when it dropped `std.json` for a parser whose valid
inputs cannot reach the dangerous paths — and escaping is exactly the class of
thing a hurried LLM gets wrong.

Verified 2026-07-28: 123 bytes of prose containing `"`, `\`, blank lines and
markdown encoded to 151 bytes, zero dangerous characters, byte-identical
roundtrip.

> **Never use `-n` / `--crlf`.** It preserves literal newlines, which would put
> a raw newline inside a record and break NDJSON's one-record-per-line
> invariant. `-s` alone is correct. This is precisely the kind of
> plausible-looking "improvement" an ADR exists to prevent.

## 4. Storage

`<project>/ADR.ndjson`, committed. Rationale:

- Per-project, because `~/Code` is deliberately not a repo.
- Committed, because a decision log that is not version-controlled loses the
  one thing that makes it trustworthy — its own history.
- Single file, because append-only NDJSON survives concurrent agents far better
  than a directory of numbered markdown files, which collide on the next index.

Privacy: `ADR.ndjson` is committed and some repos are public. Anything personal
belongs in `~/MEMORIES/`, not here — same rule the `memories` skill applies.

## 5. Capture — a deliberately invoked skill

**Peter's choice, 2026-07-28: manual only.** An `adr` skill that appends one
record when an agent or Peter judges a real decision was made.

The tradeoff was made with eyes open. Automatic `Stop`-hook capture (the
`code_my_spec` approach) never forgets, but manufactures records for trivial
turns; a log at 90% noise is unsearchable, and unsearchable defeats the entire
purpose. Manual capture yields fewer records of much higher signal, and the
failure mode — a decision that never got recorded — is a *known* gap. That is
strictly better than the alternative failure mode, which is a real record
buried under two hundred fake ones.

Revisit if, after a month of real use, the log is visibly missing decisions
that mattered.

## 6. Retrieval — a `PreToolUse` hook (this is the crux)

**Peter's choice, 2026-07-28.** This is the half that determines whether the
system is worth anything.

On `PreToolUse` for `Edit` / `Write`, match the target path against every
record's `where`, and inject any hits as additional context before the edit
happens.

The asymmetry with section 5 is deliberate and correct: **write deliberately,
read automatically.** A record you never wrote is a gap you can discover. A
record you *had* and didn't read at the moment you reached for the fence is the
actual Chesterton's Fence failure — the exact thing this exists to prevent. So
retrieval must not depend on anyone remembering to ask.

Design constraints:

- **Must fail open.** An interactive hook that blocks edits when its matcher
  errors would make the fleet unusable. Same reasoning as `shellcheck-gate`
  (and unlike a CI gate, which should fail closed).
- **Must be fast.** It runs before every edit. A linear scan of an NDJSON file
  is fine at thousands of records; revisit only when measured, not before.
- **Must be quiet on a miss.** Most edits touch no fence. Silence on no-match
  is required or agents learn to ignore the output.
- **Surfaces `who` prominently.** "Peter decided this" and "an agent decided
  this unreviewed" warrant very different levels of caution, and that
  distinction is the reason the field exists.

## 7. Open questions

- **Granularity of `where`.** File-level is the obvious start. Symbol- or
  line-level is more precise but rots immediately as code moves. Start at file
  level and see whether precision is actually missed.
- **Does the hook fire on read paths too?** Reading before changing is when a
  fence matters most, but hooking every `Read` is likely too noisy.
- **Cross-project decisions.** Some fences are fleet-wide (the C-CLI/FFI rule,
  the `-n` prohibition above). A per-project `ADR.ndjson` cannot express those.
  Possibly a shared root, possibly they belong in `~/MEMORIES/` instead — the
  boundary between "durable lesson" (memories) and "decision with alternatives"
  (ADR) needs drawing before both exist and drift.
- **Retrofitting.** There are years of undocumented fences. Do not bulk-generate
  records for them; an ADR reconstructed by an agent guessing at intent is worse
  than no ADR, because it *looks* authoritative. Record decisions going forward,
  and backfill only where a human can state the actual reason.

## 8. Testing (before any of this ships)

Per Peter's standing rule, the matcher is a **filter, so it gets tested as a
classifier over sets** — sensitivity and specificity corpora — not as a
predicate over a few happy-path examples:

- Paths that must match a record's `where` (including glob forms).
- Paths that must **not** match — especially near-misses like
  `accentd.nix` vs `accentd.nix.bak`, and a path that is a *substring* of a
  recorded one.
- Malformed records: truncated line, unknown `who`, missing `where`, prose in
  `where`. Each must be reported, never silently skipped — a skipped record is
  an unexplained fence.
- Roundtrip: every `_pb` field decodes byte-identically to what was written.
