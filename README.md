# llm_skills

[![Mechatron Prime CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fthelio-nixos.tail66c90.ts.net%2Fbadges%2Fllm_skills.json&style=for-the-badge)](https://thelio-nixos.tail66c90.ts.net/mechatron-prime/)

A collection of cross-cutting skills for
[Claude Code](https://docs.claude.com/en/docs/claude-code/overview),
[Codex](https://developers.openai.com/codex/skills/), and compatible agent
harnesses. Each skill is a focused procedure that an agent invokes when its
task matches the skill description.

This repo is the canonical home for general-purpose skills that aren't
tied to any single project. Project-coupled skills (skills whose job IS
to document one specific tool's protocol or workflow) live in their own
project's repo and are symlinked in.

For Codex compatibility, link the entire project-coupled skill directory and
keep `SKILL.md` as a real file in the target. Codex 0.146 follows the directory
link but ignores a symlink used only for `SKILL.md`.

## Install

```sh
git clone https://github.com/pmarreck/llm_skills.git
cd llm_skills
./install
```

The default installer links this physical repository to
`$HOME/.claude/skills`. It describes its plan before prompting, backs up a
displaced path, and is idempotent.

Current Codex releases discover personal skills under
`$HOME/.agents/skills` and follow skill-directory symlinks. Install the same
physical repository for Codex with:

```sh
./install --codex
```

That mode links `$HOME/.agents/skills` directly to this repository. During an
upgrade from the pre-0.146 materialized-copy layout, it moves only legacy
`$HOME/.codex/skills/<name>` directories owned by this repository into a
recoverable `$HOME/.codex/backups/llm-skills-zero-copy.*` directory. Codex's
`.system` bundle and unknown local-only skills remain in place.

No synchronization hook is needed because Claude and Codex read the same
files. The retired `--sync` and `--from-hook` options fail with an explanation
instead of silently preserving the old architecture. The installer uses
portable Bash, Git, `find`, `ln`, `mv`, and `mktemp` forms supported on macOS
and Linux.

Other LLM coding harnesses (Gemini CLI, etc.) often follow the same
`~/.<harness>/skills/` convention; symlinking this repo may work for
them, depending on their discovery rules. The skills themselves are
plain Markdown with YAML frontmatter and are not specific to either Claude or
Codex.

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
| [`capture-collaboration-evidence`](capture-collaboration-evidence/SKILL.md) | Proactively preserving artifact-backed cases of exceptional human-agent synthesis |
| [`dispatch`](dispatch/SKILL.md) | Dispatching background subagents for substantial parallel work with checkpointing |
| [`handoff`](handoff/SKILL.md) | Writing a session handoff document so a fresh agent can pick up the work with full purpose + intent |
| [`i18n`](i18n/SKILL.md) | Any user-facing UI work involving translations, locales, `--lang`, RTL, or bilingual errors |
| [`memories`](memories/SKILL.md) | Curate, validate, consolidate, and promote durable shared/project memory lessons |
| [`ship`](ship/SKILL.md) | Shipping work — commit/push, CI watch, tagged releases |
| [`mechatron-ci`](mechatron-ci/SKILL.md) | Configure or audit a project for Thelio-hosted Mechatron Prime CI |

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
| `llmsend` | [`llmsend`](https://github.com/pmarreck/llmsend) (separate repo) | Coordinating between agent sessions running sibling projects via inbox notes + tmux pings |

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
