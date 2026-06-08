# llm_skills

A collection of cross-cutting [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
skills — focused, repeatable procedures that an LLM coding agent invokes
on demand when the situation matches.

This repo is the canonical home for general-purpose skills that aren't
tied to any single project. Project-coupled skills (skills whose job IS
to document one specific tool's protocol or workflow) live in their own
project's repo and are symlinked in.

## Install

```sh
git clone https://github.com/pmarreck/llm_skills.git
cd llm_skills
./install
```

The installer symlinks this clone to `$HOME/.claude/skills/`. It is
idempotent (re-running it on an already-installed clone is a no-op),
safe (backs up any existing `~/.claude/skills` directory or
foreign-target symlink to `.bak.<timestamp>` before linking), and
describes its full plan before prompting for confirmation.

Other LLM coding harnesses (Codex, Gemini CLI, etc.) often follow the
same `~/.<harness>/skills/` convention; symlinking this repo into their
skill paths works the same way. The skills themselves are plain
Markdown with YAML frontmatter — they're not Claude-Code-specific in
content, only in discovery.

## How skills work

Each skill is a single `SKILL.md` file under a named directory:

```
i18n/
  SKILL.md            <- the skill content, with name + description frontmatter
```

When the agent's context matches the skill's `description` trigger
(e.g. "user mentions translating a CLI"), the harness presents the full
content for the agent to follow. Skills don't execute on their own —
they're invoked, read, and applied as the agent's working memory for
that turn or task.

See Anthropic's [Skills documentation](https://docs.claude.com/en/docs/agents-and-tools/skills/overview)
for the full mechanism.

## Skills in this repo

### Cross-cutting workflow

| Skill | Trigger |
|---|---|
| [`deep-code-review`](deep-code-review/SKILL.md) | Auditing a codebase or major subsystem for quality + missed issues |
| [`dispatch`](dispatch/SKILL.md) | Dispatching background subagents for substantial parallel work with checkpointing |
| [`handoff`](handoff/SKILL.md) | Writing a session handoff document so a fresh agent can pick up the work with full purpose + intent |
| [`i18n`](i18n/SKILL.md) | Any user-facing UI work involving translations, locales, `--lang`, RTL, or bilingual errors |
| [`ship`](ship/SKILL.md) | Shipping work — commit/push, CI watch, tagged releases |

### Zig-specific

| Skill | Trigger |
|---|---|
| [`scaffold-zig-project`](scaffold-zig-project/SKILL.md) | Starting a new Zig project from scratch |
| [`fix-zig-deps-hash`](fix-zig-deps-hash/SKILL.md) | `nix build` fails with zigDeps/zigDepsHash mismatch after `build.zig.zon` changed |
| [`llvm-guided-optimization`](llvm-guided-optimization/SKILL.md) | Optimizing Zig hot paths via LLVM IR after algorithmic gains are exhausted |
| [`zig-microbenchmarks`](zig-microbenchmarks/SKILL.md) | Adding benchmarks, tracking hot-path performance, investigating regressions |

### Project-coupled (symlinked in from their home projects)

| Skill | Lives in | Trigger |
|---|---|---|
| `LLMsend` | [`llmsend`](https://github.com/pmarreck/llmsend) (separate repo) | Coordinating between Claude Code sessions running sibling projects via inbox notes + tmux pings |

## Authoring a new skill

Two principles decide where a new skill lives:

1. **Cross-cutting** (applies across many projects, owned by none) → in
   this repo, as `<skill-name>/SKILL.md`.
2. **Project-coupled** (the skill IS the canonical protocol or docs for
   one specific tool) → in that tool's repo, symlinked back here.

A `SKILL.md` looks like this:

```markdown
---
name: skill-name
description: Use when ...  (this string drives trigger matching — be specific about when this skill applies, not what it does)
---

# Skill title — short tagline

Brief overview of what the skill is for.

## When to invoke

- Concrete trigger 1
- Concrete trigger 2
...

## How to apply

The actual procedure / rules / checklist the agent should follow.
```

The `description` field is the most important word in the file — that's
what the harness pattern-matches against to decide whether to surface
the skill. Make it specific, name the conditions, mention the trigger
words a user is likely to say.

## License

MIT — see [`LICENSE`](LICENSE).
