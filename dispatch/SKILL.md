---
name: dispatch
description: Use when dispatching background subagents for substantial tasks, especially fanning out parallel work that needs progress checkpointing.
---

# Dispatch

Wraps subagent dispatch with a standard discipline preamble. The goal is that **any** agent you fan out, whether one or five, behaves predictably: it keeps state externalized, fails honestly, and leaves a trail even if cut off.

<when_to_use>
- Dispatching **any** subagent for non-trivial work (> 5 minutes of expected wall-time).
- Fanning out **2+ parallel** agents, especially when they'll touch shared infrastructure (build files, lockfiles, dependency manifests, top-level config — anything multiple agents would want to edit at once).
- Tasks where turn-budget cutoff is a realistic risk (large dependency integrations, cross-platform validation, multi-step debugging).
</when_to_use>

<when_not_to_use>
Simple one-shot queries ("summarize this file", "count foo in bar") — the overhead isn't worth it. Use Agent directly.
</when_not_to_use>

<invocation>
The skill doesn't have a dedicated CLI; it's a prompt-composition discipline. When the user or the parent agent decides to dispatch, this skill's **Preamble** (below) gets prepended to the task prompt before it goes to `Agent(...)`. For parallel fan-outs, optionally use git worktrees per agent (see *Worktree isolation* below).
</invocation>

## Preamble (inject into every dispatched prompt)

<template>
## Dispatch discipline (from /dispatch skill)

### State externalization — MANDATORY
At the very start, create a progress doc at `/tmp/dispatch-log/<slug>-progress.md`
with this template:

    # <task> — progress log
    Agent ID: <the id printed after spawn>
    Started: <iso8601 timestamp>
    Brief: <one sentence describing the task>

    ## Plan checklist
    - [ ] <first concrete step>
    - [ ] <second>
    - [ ] ... (fill in before you start)

    ## Activity log
    <append one line with timestamp + 5-15 words per meaningful step>

After every completed checklist item OR after every 5 tool calls (whichever
first), re-write the file with updated checkboxes and append the new activity
lines. If you hit a turn-budget cutoff, this file is the only trail we have —
treat it as the most important output after the actual code.

### Final report — MANDATORY, even if incomplete
Before you finish (whether success, partial success, or stuck), write
`/tmp/dispatch-log/<slug>-final.md` containing:

    - Status (done / partial / blocked)
    - Where you stopped and why
    - Files created/modified/reverted (with paths)
    - Commits (with hashes) if any
    - Before/after measurements if relevant
    - What went wrong and pitfalls to warn the next agent
    - Minimum next-steps for a retry

"I got 80% done and ran out" with a clear list is MUCH more valuable than
a polished summary that papers over failures.

### Harness wait patterns
- Long-running commands: use `run_in_background: true` on Bash, THEN wait
  for the completion notification. You are automatically told when a
  background task finishes — do not poll.
- Multiple events from a running process: use Monitor with a proper `until`
  loop that emits on every terminal state, not just success.
- NEVER use `sleep N && tail ...` — the harness explicitly blocks it.
- NEVER sleep to "wait for a build to finish" — use run_in_background.

### Peer-agent coordination (for parallel dispatches)
If you suspect another agent is concurrently editing the same files:
- **Never revert another agent's uncommitted work to clean your build.**
  Stash your own changes, open a worktree, or wait — do not destroy theirs.
- If a build is broken by a peer's WIP, say so explicitly in the progress
  doc instead of silently fixing it. The parent will reconcile.
- If you're about to touch shared infrastructure (top-level build files,
  dependency manifests, lockfiles, CI config), re-read the file IMMEDIATELY
  before each edit — version snapshots go stale under concurrent writes.
  Tools that edit by line number or content hash will silently no-op on
  version mismatch.

### Project skills — USE THEM
Before doing manual work, check if a project-local or user-level skill
already solves it (run `Skill` tool list at session start, or check
`~/.claude/skills/`). Common reusable ones include skills for:
- Dependency / lockfile hash recovery after a failed build.
- Commit + push + CI-watching when work is done.
- Microbenchmark setup for perf-sensitive paths.

### TDD discipline
For bugfixes and new features:
1. Write a failing test FIRST that expresses the expected behavior.
2. Run it, confirm it fails (if it passes, the test is wrong).
3. Write the minimal implementation to pass.
4. Run it, confirm pass.
5. Run the full project test suite, confirm no regressions.
6. Only commit if all tests pass.

Exception: pure refactors under adequate existing coverage.

### Honest-failure preference
A commit that says "I got to X, Y remains because Z" is always better than
a commit that LOOKS done but isn't. If you can't make tests pass, don't
commit; report what's broken. If you can't add a feature cleanly, don't
half-add it; report why and what the clean path would be.

### Time calibration
LLM wall-time ≠ human wall-time. Tasks that a human would estimate as
"1-2 weeks" are often a single session for you. Don't pre-decide a task is
too big — start, make progress, report where you got.

### Coding standards (when touching this repo)
Refer to `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` in the project root
for project-specific conventions (indentation, naming, comment style,
test conventions). When in doubt, mirror the surrounding code. Avoid
mocking the thing under test; prefer deterministic, seeded tests.

### Codescan worktree co-location (run ONCE at agent startup)
If you are running inside a git worktree AND the parent project has a
`.codescan/` index, clone it into the worktree's root and start a local
watcher. Without this, codescan tools resolve paths against the parent's
index and your edits leak there instead of staying in your worktree.

```bash
# Detect parent .codescan/ — walk up from the worktree root until found.
PARENT_CODESCAN=""
DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
while [ -n "$DIR" ] && [ "$DIR" != "/" ]; do
    PARENT="$(dirname "$DIR")"
    if [ -d "$PARENT/.codescan" ]; then
        PARENT_CODESCAN="$PARENT/.codescan"
        break
    fi
    DIR="$PARENT"
done

if [ -n "$PARENT_CODESCAN" ] && [ ! -d "./.codescan" ]; then
    # APFS clonefile — instant, ~zero disk until divergence.
    cp -c -R "$PARENT_CODESCAN" ./.codescan 2>/dev/null \
        || cp -R "$PARENT_CODESCAN" ./.codescan   # non-macOS fallback
    codescan watch start 2>/dev/null || true
fi
```

Run this as the first thing in the worktree, before any codescan tool
call or edit. Idempotent — safe to skip if already done.

### Codescan watcher teardown (run as part of final report)
Pair the startup with a teardown. Watchers outlive the worktree if
not explicitly stopped, and orphaned watchers are wasteful (they keep
re-indexing a directory tree that may be about to be cleaned up).

```bash
# In the same shell where the worktree's .codescan exists:
codescan watch stop 2>/dev/null || true
```

Run this BEFORE writing the final report (so the report can confirm
the watcher state) but AFTER your last codescan tool call. The
worktree's `.codescan/` directory itself goes with the worktree on
cleanup-on-no-changes; only the watcher process needs explicit stop.

If you crash or hit a turn-budget cutoff before reaching teardown,
the parent will reap orphaned watchers via
`codescan watcher status` — not catastrophic, just untidy.
</template>

## Worktree isolation (for parallel fan-outs touching shared infra)

When dispatching ≥ 2 agents that'll each modify the same top-level build files, dependency manifests, or lockfiles, prefer giving each its own git worktree. The Agent tool supports `isolation: "worktree"` — use it.

<remember>
Worktree rules baked into the preamble already handle the case where you did NOT use worktrees; but worktrees eliminate the coordination hazard entirely.
</remember>

### Codescan + worktrees

A subtle gotcha: codescan resolves the project root by walking up the directory tree until it finds the nearest `.codescan/`. Without intervention, an agent in a worktree finds the **parent** project's `.codescan/` (because the worktree itself doesn't have one) — and codescan's path-edit tools land back on the parent's main checkout, leaking edits out of the agent's worktree.

The preamble's "Codescan worktree co-location" step fixes this by clonefile-copying the parent's `.codescan/` into the worktree at agent startup and starting a local watcher. The clone is near-zero disk on macOS APFS and gets cleaned up with the worktree.

<important>
This behavior is automatic via the preamble. You do NOT need to do it manually before dispatching — the agent runs the snippet itself as its first action. But if the dispatch is on a system without `.codescan/` indexing, the snippet is a no-op. Confirm codescan is the active path-resolution tool before relying on it.
</important>

## Post-dispatch review (for the parent agent)

After one or more agents complete, the parent should:

1. Read each agent's `<slug>-final.md` (small, bounded — safe).
2. Cross-check that final claims match the git log + file state.
3. For parallel dispatches, check whether any agent reverted another's work and whether that revert was intentional.
4. If an agent was cut off, spawn a summarizer on its JSONL transcript:

<example>
Summarize `/private/tmp/claude-.../tasks/<agentId>.output`. Report what got built, what was reverted, where it stopped, and minimum next-steps.
</example>

(The summarizer's output fits in your context even though the raw JSONL would overflow.)

## Slug naming

<important>
Use short, kebab-case, task-indicative slugs. Good: `auth-refactor`, `pdf-streams`, `api-rate-limit`. Bad: `task-1`, `agent-2`, `foo`.
</important>

The slug appears in both progress and final doc paths and becomes the parent's primary handle for reviewing the work.
