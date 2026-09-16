# Shared agent skills

This repository provides reusable, project-independent working guidance for
Claude Code, Codex and other agents that can read Markdown skills. Its purpose
and boundaries are established in the [README](README.md).

Skills should preserve useful engineering decisions across conversations while
loading only the guidance relevant to the task. Public instructions must remain
shareable; private personal context lives outside this repository. Tool-specific
skills belong to their tool repositories and may be linked here.

The installed shared tree should expose the same canonical content to supported
agents without copy-and-sync drift. Skills describe workflows and constraints;
they do not grant additional execution authority. Do not include bundled agent
system skills in this repository.

Success is evidenced by readable, scoped instructions, working references,
installation/discovery checks and tested behavior for executable helpers.
Prose and file-presence tests alone cannot prove that an agent or a downstream
project follows the instructions. The full local suite is `./test`; packaging
and isolated checks are declared in `flake.nix`. Current work lives in [PLAN.md](PLAN.md).
