# Benchmark and fuzz entry points

The benchmark contract is now owned by the cross-agent
[performance-profiling skill](performance-profiling/SKILL.md). Its references
cover runtime, complexity, memory, external history and acceptance. The July 31
benchmark proposal is superseded; do not reintroduce source-tracked measurement
logs, implicit rerun acceptance or automatic historical passes on new machines.

## Fuzzing contract

- `./fuzz` is an executable Bash entry point with a bounded default campaign
  that terminates; `--forever` or a duration may provide longer local exploration.
- Required bounded acceptance checks and every discovered regression remain
  reachable from the complete `./test`. Long campaigns need not run there.
- Campaigns use a recorded seed and versioned corpus. Prefer the `random`
  project for reproducible randomized fixtures rather than a new ad hoc PRNG.
- Record seed, iterations, duration, build mode, sanitizer set, finding count,
  commit, machine/runtime identity and timezone-aware datetime.
- Build safety-enabled targets (Zig ReleaseSafe or appropriate sanitizers),
  rather than stripping safety checks for benchmark speed. Performance builds
  are a separate concern. Keep crash inputs and reproduction commands.
- Every fixed crash becomes a permanent regression test. Small corpora can be
  source-controlled; larger ones need a recorded reproducible acquisition or
  generation method.

Suggested layout retains `fuzz/findings/<seed>-<description>/` and `fuzz/corpus/`.
No new campaign service or fleet-wide rewrite is implied by this reference.
