---
name: erect-agent-stack
description: Start or rejoin a project's persistent coding agent in Herdr, preserving its directory, agent identity and conversation context. Use when asked to spin up an agent, restore an exited project agent, or establish a recipient for a cross-project handoff. Default to Claude for a new agent; preserve the backend when restoring one.
---

# Erect agent stack

Herdr is the default project-agent multiplexer (Peter, 2026-09-10). Keep one
project per named workspace unless Peter requests another layout. This workflow
is shared by all agent clients.

The historical dotfiles executable named `erect-agent-stack` still targets
tmux. Do not invoke it for this workflow or silently fall back to tmux. Use
Herdr's native controls below; tmux is only for explicitly requested legacy work.

## Discover and reuse

1. Verify `test "${HERDR_ENV:-}" = 1`. If absent, stop terminal orchestration
   and ask to resume inside the intended Herdr session. Do not manufacture the
   environment marker or target another client's focused session.
2. Read `herdr --skill` completely for the installed CLI's contract. Use
   command-group help or `--help`, never bare `herdr` (which attaches the
   TUI), nor a mutating command with omitted arguments as a discovery probe.
3. Resolve bare names under `$HOME/Code`, supplied paths as-is; confirm the
   directory exists. This skill does not scaffold missing projects.
4. Read `herdr workspace list`, `herdr agent list`, and candidate
   `herdr pane list --workspace ID` results. Match canonical cwd as well as
   label/name. A basename alone is insufficient. Resolve ambiguous matches
   with Peter rather than guessing.

Prefer project basename for workspace label and agent name. Herdr agent names
must match `[a-z][a-z0-9_-]{0,31}` and be unique; record any necessary alias.
Names are live handles, not durable conversation IDs, and clear on agent exit.

| Observed state | Action |
|---|---|
| Matching live agent | Reuse; do not launch a second writer or change its context. |
| Existing workspace, confirmed idle shell | Start there; preserve workspace/tab. |
| Existing workspace, occupied/ambiguous pane | Inspect; use a confirmed spare shell or ask before replacing anything. |
| No matching workspace | Create one at the project root without taking focus. |

## Context and kickoff

Write the durable kickoff note first using `llmsend`. Include accepted
decisions, current implementation versus remaining work, tests, reply
destination and permission boundaries. A live recipient receives the note,
not a replacement agent.

For restoration, preserve the last backend and resume the exact native
conversation ID when known. Inspect Herdr `agent_session` metadata and saved
snapshot/handoff. If only last-in-directory continuation is available, verify
cwd and report that weaker identity guarantee. Never silently replace a failed
resume with fresh context. A genuinely new project agent starts fresh; avoid
accidental continuation through a shell wrapper.

## Launch

When a new project workspace is needed:

```bash
herdr workspace create --cwd "$project_dir" --label "$project_name" --no-focus
```

Parse the returned `.result.root_pane.pane_id` and workspace ID. Use those exact
handles, never sidebar positions or another client's focus. Confirm the pane
is at an interactive shell before starting an agent.

Use Peter's requested backend, otherwise the existing backend on restoration,
otherwise Claude. Discover installed native options with `--help`. Use native
unrestricted mode per Peter's standing launch instruction, within task scope:

```bash
herdr agent start "$project_name" --kind claude --pane "$pane_id" -- --dangerously-skip-permissions
# Codex: --kind codex ... -- --dangerously-bypass-approvals-and-sandbox
```

Pass resume/model/permission arguments after `--`, using installed CLI syntax.
Do not require API-key variables when the client already has a subscription
login. Inspect actual authentication failures. Herdr remote access does not
require starting a separate provider remote-control daemon.

`agent start` waits for readiness. Timeout or `agent_not_ready` does not prove
the process failed to start. Inspect `agent get` and `agent read` before
retrying. Peter authorizes accepting a trust prompt for the explicitly requested
project after verifying cwd and actual displayed choices. Do not match entire
prompt wording, blindly press Enter, or approve unrelated dialogs.

## Deliver and verify

The inbox monitor may already have started work. Inspect before sending a
duplicate prompt. If an authorized wake is needed, follow `llmsend`'s
empty-prompt inspection and use:

```bash
herdr agent read "$project_name" --source recent-unwrapped --lines 40
herdr agent prompt "$project_name" "Read the kickoff note at $note_path and begin the assigned work."
herdr agent get "$project_name"
```

Use Herdr's agent API rather than recreating tmux/Kitty keystroke recipes.
Readiness, queued input and `done` alone do not prove the note was read; seek
acknowledgement or observed reading/action on that specific note. Inspect and
report blocked/unknown states.

Record workspace label/ID, pane ID, canonical cwd, backend and native session ID
when available in the existing launch snapshot/handoff. Report reuse, resume
or fresh launch accurately. Herdr topology is not a backup of transcripts.

Do not stop the Herdr server, move existing panes, close unrelated workspaces
or steal focus during a background launch.
