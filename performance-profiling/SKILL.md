---
name: performance-profiling
description: Design, implement or investigate runtime benchmarks, complexity gates, allocation/memory growth and leak controls, or their measurement history. Use for bm/cg/mg integration and performance regressions; not for unrelated correctness tests or ordinary build work.
---

# Performance profiling

Use one shared measurement/evaluation engine with language adapters. The
approved contract separates fixed-workload timing, input-growth evidence and
memory cleanup. An unexpectedly faster or smaller result deserves review too.

Read the references relevant to the task:

- [Time and complexity](references/time-and-complexity.md) for workloads,
  startup, clocks, growth sweeps, noise and benchmark commands.
- [Memory](references/memory.md) for allocator coverage, growth, residuals and RSS.
- [History and acceptance](references/history-and-acceptance.md) before implementing
  storage, historical comparisons, retries, CI integration or baseline changes.
- [Language adapters](references/language-adapters.md) when implementing a probe,
  especially for Zig, C FFI or LuaJIT.

## Existing tool and command boundary

The first reusable implementation is `$HOME/Code/performance_profiling`.
Read its `README.md` and `docs/CONTRACT.md` before adopting it. Its CLI is
`performance-profile`; `./build` packages it with Nix. Add the pinned package
to a consuming project's devShell instead of assuming a global interpreter
has cjson, luv or the printable-binary map. Do not copy its baseline engine
into each project. A missing checkout is a dependency to resolve, not permission
to invent a second engine or claim a gate passed.

| Entry point | Purpose |
| --- | --- |
| `./cg` | Bounded input-growth and historical ratio checks |
| `./mg` | Bounded memory growth, peak usage and cleanup checks |
| `./bm` | Thorough fixed-workload, startup and scaling measurements |
| `./test` | All correctness suites and required bounded gates |

Root commands are Bash entry points delegating to the same engine and adapters.
Measure the quick-gate budget; under one second is a target, not a reason to
discard evidence. Long benchmark/fuzz campaigns can stay separate, while
acceptance-critical checks and discovered regressions remain in `./test`.

## Single-core and multicore cases

Measure each timing workload twice, as separate cases: single-core
(`cores: 1`) and multicore (12 cores unless the project states otherwise).
Some code parallelizes underneath (runtimes, allocators, libraries) and some
does not; one measurement cannot show both. Every case declares `cores`; the
engine pins Linux runs with `taskset` (override the CPU pool with
`PERFORMANCE_CPUS`), passes `PERFORMANCE_CORES` to the command, puts the count
and enforcement method in the cohort, and records the exact CPU list. Requesting
more cores than are available is an error, not a smaller run. Where affinity
cannot be enforced (macOS), the record says `unenforced`. Deterministic metrics
(allocation counts, operations) need not be measured twice unless the code's
behavior depends on the core count.

## Run-to-run state, process modes and anchors

- Each timed sample starts from the state a real run would see. A program that
  normally runs once per process gets a settled heap before every sample
  (collect until the heap stops shrinking, outside timing), so the harness's
  own earlier runs do not leave garbage-collector or string-table state for
  later samples to pay for. Record that settling happened. Long-running
  behavior is a separate steady-state case that runs back to back without it.
- A JIT can settle into different modes in different processes. Where a
  workload shows that, declare an odd `processes` count: the engine gates on
  the median fresh process and keeps all of them. Do not average modes.
- Size sweeps so the largest point is long enough to measure under load and
  short enough to keep the gate quick (about 150 ms worked for one LuaJIT
  project); drop sizes too short to measure rather than widen tolerances.
- Before accepting an observation as an anchor, check its per-size sample
  spread and ratios. A noisy smallest size can anchor a wrong ratio that the
  next clean run then fails against.

## Non-negotiable comparison boundaries

Measure verified work in an optimized build. Prepare/warm up in the process,
outside steady-state timing. Keep CPU and monotonic wall measurements distinct.
No zero-on-clock-error, Debug skip, guessed startup subtraction or hidden crossover.

Read and freeze the historical baseline before the new measurement is recorded.
Use hardware/runtime/measurement-qualified cohorts, two-sided configurable
historical bounds and independent declared-shape/resource bounds. Finite sweeps
are evidence, not Big-O proofs. New hardware is unbaselined, not automatically green.

History lives outside the measured repository in a project-configured URL.
V1 supports an absolute `file://` directory and project-named immutable NDJSON
records. Both local and CI use the same pipeline outside the Nix build sandbox;
cached derivations are not fresh host measurements.

Delegate CI setup to the `mechatron-ci` skill and its exact-commit
`.mechatron-prime/targets` manifest. Coordinate fresh outside-sandbox measurements
with the runner owner; adding a cached Nix check alone does not wire that pipeline.

An otherwise valid timing failure gets at most one complete retry. Only its
selected passing measurement can become a normal baseline observation. Nested
failed attempts are diagnostic data, never baseline candidates. A rerun cannot
approve an epoch. Explicit owner-approved acceptance records the exact run and
reason; do not have an agent or automatic CI retry approve its own regression.
Correctness failures, leaks and declared-shape violations are not accepted this way.

Scope adoption to the requested project. This skill does not authorize fleet
rewrites, host scheduling changes, privileged storage provisioning or publication
of private command/source metadata.
