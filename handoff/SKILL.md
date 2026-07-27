---
name: handoff
description: Condense the current state of development affairs into a handoff document for another agent to pick up, and give that agent a sense of purpose and intent.
---

# handoff — write a session handoff document for the next agent

A handoff document is the bridge between sessions. A new agent
(human or LLM) arriving cold should be able to read one file and
immediately understand why the project exists, what just happened,
what's still in motion, and what to do next — *and then proceed
directly into the work without further investigation.*

**Completeness over brevity.** The document should be long enough to
cover everything the next agent needs to act, including the purpose,
the recent decisions and why they were made, the current state, the
open questions, and any environmental gotchas the current session
discovered. Length is fine; missing context is not. Where another
artifact already holds the truth (a `PLAN.md`, a SPEC, a commit
message, a GitHub issue), reference it by path/line/URL and include
a one-to-three-sentence summary so the next agent can choose whether
to read the source or rely on your summary. Reference rather than
duplicate, but do not omit.

## When to invoke

- The user types `/handoff` (with or without an argument describing
  the next session's focus).
- The user says "wrap up", "hand this off", "write a handoff",
  "context's getting low — summarize for next time", or similar.
- You are about to be compacted or replaced and want to leave a
  durable summary.

## Procedure

### Step 0 — read prior HANDOFFs FIRST (before deleting them)

If older `HANDOFF-*.md` files exist in the working directory, **read
them before doing anything else**. They may already contain a
PURPOSE & INTENT section you can build on (preventing drift), and you
need to extract anything that's still relevant to the new doc before
moving the old ones to Trash.

```bash
find . -maxdepth 1 -type f -name "HANDOFF-*.md" -print
```

For each older HANDOFF doc: read it, mentally merge any still-current
PURPOSE & INTENT framing into your draft. Then mark it for cleanup
(step 5).

### Step 1 — establish PURPOSE & INTENT

This is the most important section of the handoff. It is **always
first** in the output. It captures the WHY, not the what.

Required sub-sections:

- **WHY we are building** — the underlying motivation. Not "we are
  writing a CLI tool" but "the user has no surgical way to fix X
  without losing Y, and existing tooling forces the bad tradeoff."
- **RECENT GOAL(S) MET** — concrete goals achieved in the last
  session(s). Bullet form, with brief evidence (commit, file, URL).
- **IMMEDIATE GOAL(S)** — the goal the next session should work
  toward. There may be one, or a small ordered list.
- **ULTIMATE GOAL** — the long-arc vision the project exists to
  realize. A new agent should be able to use this to decide whether a
  proposed change pulls toward or away from the destination.
- **How the current/next task advances those goals** — one or two
  sentences connecting the immediate work to the immediate + ultimate
  goals. This is the "sense of intent" the next agent inherits.

If you are unsure of any of WHY / RECENT / IMMEDIATE / ULTIMATE:

1. First check older HANDOFF-*.md files in the working dir (you
   already read them in step 0); reuse and refine their framing.
2. Then check top-level project docs (`PROJECT_OVERVIEW.md`,
   `PLAN.md`, `docs/SPEC.md`, etc.) for the project's stated vision.
3. If still unsure, **ASK the user to clarify before writing the
   document**. Do not invent purpose; an invented purpose poisons
   every downstream session that reads it.

If the user passed an argument to `/handoff`, treat the argument as a
description of what the next session will focus on. The PURPOSE &
INTENT section should make that focus visible in the IMMEDIATE GOAL
sub-section and the "how this advances the goals" sentence. The rest
of the handoff (Completed / In-Flight / Next) should be slanted to
prioritize information relevant to that focus.

### Step 1a — audit branch provenance

Before writing, inspect Git branch ownership and ancestry without mutating
refs:

```bash
git for-each-ref \
  --format='%(refname:short)|%(objectname)|upstream=%(upstream:short)|track=%(upstream:track)|%(subject)' \
  refs/heads refs/remotes
git ls-remote --heads origin
git worktree list --porcelain
```

For every non-primary or suspicious branch, record its exact ref/SHA, upstream
or authoritative remote head, linked worktree (if any), ahead/behind counts,
merge-base, unique commits, and enough reflog plus author/committer metadata to
explain where it came from. Treat missing tracking, unrelated ancestry,
unowned worktrees, unclear unique commits, or disagreement between local
remote-tracking refs and `git ls-remote` as provenance risks.

Add a **Branch provenance** subsection to the handoff. State either that every
branch has adequate provenance, or enumerate questionable/stale branches with
evidence and a recommended human decision. Do not fetch with `--prune`, delete,
merge, rebase, or otherwise mutate a questionable branch during handoff; the
point is to preserve and surface history, not clean it up.

### Step 2 — summarize current work

After PURPOSE & INTENT, three required sections:

- **Recently completed** — what landed this session. Reference
  commits, PRs, file paths, URLs. **Do not paste content that is
  already in those artifacts** — point to them.
- **In-flight** — work started but not finished. State what's done,
  what's left, and any blockers or open questions.
- **Coming up next** — the immediate next steps the next session
  should take. Order them. If the user provided an argument, anchor
  this list around it.
- **Branch provenance** — exact local/remote branch state, tracking and
  worktree ownership, plus any stale, divergent, unrelated, or unexplained
  branch that needs a human retain/merge/delete decision.

### Step 3 — be complete; reference rather than duplicate

The document must be complete enough that a fresh agent can proceed
directly into the next unit of work after reading it. That means
capturing everything they need to act: purpose, current state,
recent decisions and the reasoning behind them, what was tried and
discarded, what is loaded into the current session's context, open
questions, environmental gotchas the current session ran into.
Length is not a goal to minimize.

"Complete" does NOT mean "paste everything wholesale." Where the
truth lives in another artifact (a `PLAN.md`, commit message,
GitHub issue, SPEC, code file), reference it by path / line /
URL, and accompany the reference with a one-to-three-sentence
summary so the next agent can decide whether to read the source
or rely on your summary. The next agent should not have to chase.

Anti-pattern (bad): copying a 50-line spec from another doc into
the handoff. Anti-pattern (also bad): writing only "see
`docs/SPEC.md` §3" with no summary, forcing a chase. Pattern
(good): "see `docs/SPEC.md` §3 (safety model) — the rule cascade
is detect → quiesce → backup → modify → verify; we are partway
through implementing the backup step (rule b), with the verify step
already covered by `tests/integration/verify_after_fix_test.zig`."

### Step 4 — redact sensitive information

Before writing, scan for and **remove or redact**:

- API keys, tokens, bearer tokens, OAuth secrets
- Passwords (including any passed via `--password`/env)
- Personal data the user has not authorized for inclusion (full names
  of third parties, email addresses, phone numbers, addresses)
- Anything from a `secrets.ini` / `.env` / similar
- Private endpoint URLs containing credentials

Replace with `[REDACTED]` or omit entirely. When in doubt, omit.

### Step 5 — write the document and clean up

Compute the filename:

```bash
ts="$(date '+%Y%m%d%H%M%S%Z')"
out="HANDOFF-${ts}.md"
```

Write the document to `./$out` at the project root.

Ensure `HANDOFF*` is in `.gitignore` (handoff docs are
session-ephemeral; they should not be committed):

```bash
if [ -f .gitignore ]; then
    grep -q '^HANDOFF\*' .gitignore || printf '\n# session handoff docs (skill: handoff)\nHANDOFF*\n' >> .gitignore
else
    printf '# session handoff docs (skill: handoff)\nHANDOFF*\n' > .gitignore
fi
```

Move older HANDOFF docs to system Trash (you read them in step 0;
they've served their purpose). This skill is OS-portable; the Trash
location differs between macOS and Linux.

**Preferred:** use `rm-safe` if it's on the PATH. `rm-safe` is a
cross-platform safe-delete helper that moves the target to the
system Trash for the current OS (macOS `~/.Trash/`, Linux
FreeDesktop XDG Trash at `~/.local/share/Trash/files/` with
restore metadata in `~/.local/share/Trash/info/`). Behaves like
`rm`, but is undoable.

```bash
if command -v rm-safe >/dev/null 2>&1; then
    find . -maxdepth 1 -type f -name "HANDOFF-*.md" ! -name "$out" \
        -exec rm-safe {} +
else
    # Fallback: detect OS and mv to the OS's Trash directory.
    case "$(uname -s)" in
        Darwin)
            trash="$HOME/.Trash"
            ;;
        Linux)
            trash="$HOME/.local/share/Trash/files"
            mkdir -p "$trash"
            ;;
        *)
            # Unknown Unix; default to a ~/.Trash convention.
            trash="$HOME/.Trash"
            mkdir -p "$trash"
            ;;
    esac
    find . -maxdepth 1 -type f -name "HANDOFF-*.md" ! -name "$out" \
        -exec mv {} "$trash/" \;
fi
```

Never `rm` outright — trash only. The user may want to recover an
older handoff.

### Step 6 — end the document with the "after-read" coda

The very last section of the handoff must instruct the next agent on
what to do with the document and what to read next. Copy this
verbatim (lightly adapted if needed) as the final section:

```markdown
---

## After reading this document

- Once you have read this handoff fully and have its context, you
  may move it to system Trash. The portable form (works regardless
  of whether your shell expands globs) uses `find`:

      find . -maxdepth 1 -name 'HANDOFF-*.md' -exec rm-safe {} +

  `rm-safe` is a cross-platform safe-delete helper that moves to
  the OS Trash with restore metadata. If it is not installed,
  substitute the OS Trash directory directly:

      # macOS
      find . -maxdepth 1 -name 'HANDOFF-*.md' -exec mv {} ~/.Trash/ \;
      # Linux (FreeDesktop XDG Trash)
      mkdir -p ~/.local/share/Trash/files
      find . -maxdepth 1 -name 'HANDOFF-*.md' \
          -exec mv {} ~/.local/share/Trash/files/ \;

  If your shell does have globbing enabled, the shorthand
  `rm-safe HANDOFF-*.md` (or the equivalent `mv`) works too. Some
  shell configurations disable globbing globally for safety; use
  `find` if you are unsure or if a glob wrapper (e.g. `glob`) is
  required in your environment. The next `/handoff` will create a
  fresh one.
- Next, read any top-level Markdown documents in this directory that
  are not yet in your context (`PROJECT_OVERVIEW.md`, `PLAN.md`,
  `RULES.md`, `AGENTS.md`, `CLAUDE.md`, `CODE_MINIMAP.md`,
  `MISTAKES.md`, `DESIRES.md`, `LEARNINGS.md`, and anything else at
  the project root). These almost always contain important
  work-related directives that this handoff references rather than
  duplicates.
```

## Document skeleton

The final document should follow this shape:

```markdown
# Session handoff — <project> — <YYYY-MM-DD HH:MM TZ>

## PURPOSE & INTENT

### WHY we are building
<one or two paragraphs>

### RECENT GOAL(S) MET
- <goal> — <evidence: commit, PR, file path, URL>
- ...

### IMMEDIATE GOAL(S)
1. <goal>
2. <goal>

### ULTIMATE GOAL
<the long arc — what this project exists to realize>

### How the next task advances these goals
<1–2 sentences connecting immediate work to immediate + ultimate goals>

## Recently completed
- <item> — see <ref>

## In-flight
- <item> — done: <X>; remaining: <Y>; blockers: <Z or none>

## Branch provenance
- <branch/ref, exact SHA, tracking/worktree/ancestry evidence, classification>

## Coming up next
1. <step>
2. <step>

---

## After reading this document
<coda from step 6 verbatim>
```

## Anti-patterns to avoid

- **Inventing PURPOSE/INTENT** when unsure. Ask the user. A wrong
  intent statement steers the next agent at every decision point.
- **Optimizing for brevity.** The doc should be complete enough that
  the next agent can act without research. If you find yourself
  omitting context because "the doc is getting long," you are
  optimizing for the wrong thing. Length is fine; gaps are not.
- **Reference without summary.** Pointing the next agent at
  `docs/SPEC.md` with no inline summary forces a chase. Every
  reference should include enough surrounding context that the
  reader can decide whether to follow it.
- **Duplicating content wholesale** that lives in `PLAN.md`, commit
  messages, or specs. Summarize and reference; do not paste.
- **Burying the PURPOSE & INTENT section** below summary content. It
  is always first.
- **Leaving secrets in the document.** Redact at write-time, not
  later — once the doc is written it may be read by the next session
  before you remember to clean it up.
- **`rm`-ing old handoffs.** Trash only. The user may want them.
- **Not adding `HANDOFF*` to `.gitignore`.** These are
  session-ephemeral; committing them clutters history.
- **Ignoring non-primary branches.** A cold successor can otherwise miss
  unmerged work, stale intent, or an unexplained ref whose cleanup would lose
  recoverable history.
- **Pasting the user's literal `/handoff` argument as the IMMEDIATE
  GOAL**. The argument is a *focus hint*; translate it into the
  project's vocabulary and goals.
