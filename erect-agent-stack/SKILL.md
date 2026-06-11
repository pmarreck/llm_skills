---
name: erect-agent-stack
description: Stand up or join a project's full agent stack — project-named tmux session, cwd'd to the project dir, running a remoted bypass-permissions Claude of the same name — in one idempotent command. Use when expanding the fleet ("spin up an agent for X", "fire up a session for Y"), or before LLMsend-ing a project that has no live session.
---

# erect-agent-stack

Thin orchestration wrapper around the tested bin tool `erect-agent-stack`
(dotfiles). The tool does the deterministic mechanics; this skill is the
*when and how* for agents (and humans — it's a plain CLI on PATH).

## Invocation

```bash
erect-agent-stack [--fresh] [--ping "<msg>"] [--no-attach] <project-name-or-path>
```

Bare names resolve to `~/Documents-CloudManaged/<name>`; paths are used as-is.
Missing dir is an error (exit 66) — this tool never scaffolds. Session name =
directory basename: the load-bearing fleet convention (LLMsend depends on it).

## Outcomes (idempotency state machine)

| stdout reports | meaning | what happened |
|---|---|---|
| `created` | no session existed | session created at project dir + agent launched |
| `joined-running` | session + live agent | **nothing touched** — reuse it |
| `joined-launched` | session existed, agentless | agent launched into it |

Callers branch on this: only `created`/`joined-launched` need a kickoff;
`joined-running` means coordinate with the *existing* agent instead.

## Orchestration etiquette

1. **Write the inbox kickoff note BEFORE erecting** (`<project>/inbox/…` per
   LLMsend), then erect with `--ping "📬 New inbox message from <you>: <path> — …"`.
   The tool waits for the agent to boot before delivering the ping.
2. Launch default is resume-then-fresh-fallback (`--resume <name>`); use
   `--fresh` when a clean context matters (most kickoffs).
3. The keystroke lore is encoded in the tool — plain `Enter` to shells,
   kitty CSI u (`$'\e[13u'`) only to a running Claude. Don't hand-roll the
   dance; that's how `--name validate_picsu` happened.
4. Humans at a real terminal get auto-attached (or `switch-client`ed inside
   tmux); agents/pipelines never do (tty-detected). `--no-attach` forces off.

## Failure modes

- Exit 64 usage / 66 missing dir / 69 agent failed to boot within
  `ERECT_BOOT_TIMEOUT` (45s default; resume-fallback already attempted).
- Test envs: `ERECT_TMUX_SOCKET` isolates onto a private tmux socket;
  `ERECT_DRY_RUN=1` prints `launch:`/`ping:` actions instead of sending.
