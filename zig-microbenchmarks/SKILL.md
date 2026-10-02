---
name: zig-microbenchmarks
description: Compatibility entry point for Zig benchmark requests; routes to the shared performance-profiling contract and Zig adapter guidance.
---

# Zig benchmarks

Read [performance-profiling](../performance-profiling/SKILL.md), then its
[language adapters](../performance-profiling/references/language-adapters.md).
That skill owns measurement, history, retries and acceptance across languages.

The previous example's append-before-compare ordering contaminated its own
baseline. Its source-tracked history, automatic rerun acceptance, Debug skips
and hardware-independence claims were superseded on October 2, 2026.
Use the shared engine; do not restore those examples as active guidance.

Delegate CI setup to the `mechatron-ci` skill, including the exact-commit
`.mechatron-prime/targets` manifest. Fresh host timing runs after the Nix build,
outside its sandbox; deterministic adapter checks can run in the build check.
