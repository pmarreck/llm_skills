---
name: erect-agent-stack
description: Stand up or join a project's full agent stack — project-named tmux session, cwd'd to the project dir, running a remoted, unrestricted coding agent of the same name (Claude by default; also Codex/Gemini/Grok via --agent) — in one idempotent command. Use when expanding the fleet ("spin up an agent for X", "fire up a session for Y"), or before LLMsend-ing a project that has no live session.
---

# erect-agent-stack

Thin orchestration wrapper around the tested bin tool `erect-agent-stack`
(dotfiles). The tool does the deterministic mechanics; this skill is the
*when and how* for agents (and humans — it's a plain CLI on PATH).

## Invocation

```bash
erect-agent-stack [--agent claude|codex|gemini|grok] [--checker] [--fresh] [--ping "<msg>"] [--no-attach] <project-name-or-path>
```

**Backends (`--agent`, default `claude`).** Each non-claude backend is gated on its
API-key env var AND its CLI being on PATH (else exit 78). Danger flags verified from
each CLI's own `--help`: `codex --dangerously-bypass-approvals-and-sandbox`,
`gemini --yolo`, `grok --yolo` (best-effort until installed). `--checker` prepends
`MFIC_ROLE=checker` to the launch — the MFIC adversarial-approver role (an independent
reviewer reasoning from the contract, ideally a *different model family* than the
producer; see the `mfic` skill). Mixing backends is how you get genuine cross-model
independence on a producer/approver pair.

Bare names resolve to `~/Code/<name>`; paths are used as-is.
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
2. Launch default continues the most recent conversation in the project
   directory (`claude --continue`; `codex resume --last`), then falls back to a
   fresh session if continuation cannot boot. Use `--fresh` when a clean
   context matters (most kickoffs).
3. The keystroke lore is encoded in the tool: plain `Enter` launches commands
   in shells; Claude uses kitty CSI u (`$'\e[13u'`) for a running-agent submit;
   Codex uses tmux bracketed paste followed by plain `Enter` so its paste-burst
   guard cannot reinterpret submission as a newline. On first launch, the tool
   accepts Codex's exact project-trust prompt once because the caller already
   requested unrestricted Codex in that directory. Don't hand-roll this dance.
4. Humans at a real terminal get auto-attached (or `switch-client`ed inside
   tmux); agents/pipelines never do (tty-detected). `--no-attach` forces off.

## Failure modes

- Exit 64 usage/unknown-agent / 66 missing dir / 78 backend unavailable
  (gate env unset or CLI not on PATH) / 69 agent failed to boot within
  `ERECT_BOOT_TIMEOUT` (120s default; resume-fallback already attempted).
- Test envs: `ERECT_TMUX_SOCKET` isolates onto a private tmux socket;
  `ERECT_DRY_RUN=1` prints `launch:`/`ping:` actions instead of sending.
