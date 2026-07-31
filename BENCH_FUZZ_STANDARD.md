# Fleet standard: `./bm` and `./fuzz` — the contract

**Status:** proposed standard, 2026-07-31 (Peter). Language-agnostic.
Complements `zig-microbenchmarks/SKILL.md`, which owns the **Zig mechanics**
(scaling-ratio gates, harness patterns, op-counters). This document owns the
**contract** every project must satisfy regardless of language.

## The problem it solves

Measured 2026-07-31 across the fleet:

| | |
|---|---|
| `./bm` exists in | jpegz, z7z, printable_binary (**3**) |
| `./fuzz` exists in | validate, jpegz (**2**) |
| Benchmark storage conventions | `validate/bench`, `jp2z/conformance/sweep.ndjson`, `z7z/tests/benchmark` — **3 different shapes** |
| Fuzzing guidance in `llm_skills` | **none** |

Results are therefore not comparable across projects, not comparable across
machines, and in several cases do not record **what optimize mode produced
them** — which makes a number meaningless, since ReleaseFast vs ReleaseSafe vs
Debug can differ by an order of magnitude.

## Rule 0 — a measurement without its build mode is not a measurement

Every stored record MUST carry the optimize/build mode (`ReleaseFast`,
`ReleaseSafe`, `Debug`, `-O2`, `-O0`, …). A benchmark log that omits it cannot
be compared with anything, including its own history.

Corollary, already fleet policy: **benchmarks run in the fastest mode
(ReleaseFast), never Debug**, and `./bm` must **assert the binary is not a debug
build** — the `DEBUG BUILD` stderr banner must be absent *and* not merely
suppressed via `MUTE_DEBUG_STATUS`.

## `./bm` — the benchmark contract

### Invocation

- Executable at project root named exactly **`bm`**, runnable with no arguments.
- No-arg run = the canonical suite. Optional `--filter <name>` to run a subset.
- Builds in the fastest mode itself; never requires a prior manual build.

### Inputs

- **Named, versioned, and fixed.** An input identified only as "the big file"
  is not reproducible. Each input gets a stable `name` recorded with the result.
- Inputs live under `tests/benchmark/` (or are generated deterministically from
  a **seed that is recorded**). Prefer generated-from-seed: it keeps the repo
  small and makes the corpus reproducible anywhere.
- Record input **size in bytes**, so throughput is derivable.

### Repetitions

- **Minimum 5 runs per measurement; report the MINIMUM, not the mean.** Minimum
  is the least noise-contaminated estimate of true cost; means are dragged by
  scheduler noise on a busy machine.
- Use **`hyperfine`** where a whole-process measurement is appropriate — it
  handles warmup and statistics correctly. Single-run scripts are too noisy to
  trust (measured: switching to hyperfine took a σ of ~30% down to ~1%).
- **CPU/user time for single-threaded compute kernels** (excludes scheduler
  noise); **wall-clock only for parallel or I/O-bound work.**

### Storage

One NDJSON record per measurement, appended to:

```
bench/<machine-id>.ndjson
```

- **`<machine-id>`** = stable hash of a configured id + arch + CPU model.
  Compare only against **the same machine's** previous entry.
- **A machine with no prior entry seeds its baseline and PASSES.** A new machine
  must never break the build.
- Source-controlled, so history is reviewable in diffs.

Required fields:

```json
{
  "name": "decode_4k_tile",
  "input": "rgb-8bit-4096.tif",
  "input_bytes": 50331648,
  "runs": 5,
  "metric": "cpu_ns",
  "value_min": 1234567,
  "optimize": "ReleaseFast",
  "lang": "zig",
  "toolchain": "zig-0.16.0",
  "machine_id": "thelio-x86_64-ryzen9",
  "commit": "9de396a4",
  "when": "2026-07-31T14:20:00-04:00"
}
```

`optimize`, `machine_id`, `commit`, and `input` are **mandatory**. Anything else
may be added; nothing may be omitted.

### Gate behaviour

- **Two-sided tolerance.** Fail if the metric moves outside tolerance in
  *either* direction — a surprise *speedup* often means lost functionality or a
  skipped code path, and is exactly as worth investigating as a slowdown.
- Tolerance: ~10% on deterministic op-counts, ~20–25% on time.
- **Re-running the benchmark is implicit acceptance** of a new baseline; that is
  the deliberate escape hatch.
- Prefer the **scaling-ratio gate** (growth shape at N, 2N, 4N, 8N) over
  absolute timings where possible — ratios are machine-independent and need no
  baseline at all. See `zig-microbenchmarks/SKILL.md`.

## `./fuzz` — the fuzzing contract

Same shape, because the same problems apply.

### Invocation

- Executable at project root named exactly **`fuzz`**.
- No-arg run = a **bounded** default campaign that terminates (CI must be able
  to run it). `--forever` or `--time <dur>` for open-ended local sessions.
- **Excluded from `./test`** — `./test` is unit + integration only.

### Determinism is mandatory

- Every campaign runs from a **recorded seed**. A crash that cannot be
  reproduced from its seed is a bug report nobody can act on.
- Use the fleet RNG (`random`, being ported to Zig as `randomz` precisely for
  this) rather than an ad-hoc PRNG, so seeds mean the same thing everywhere.
- **Corpus and seed are recorded with every finding**, along with the build
  mode — see Rule 0.

### Build mode — the one place fuzzing INVERTS the benchmark rule

**Fuzz targets build ReleaseSafe (or with sanitizers), never ReleaseFast.**

Benchmarks want ReleaseFast because they measure shipped speed. Fuzzing wants
the *checks left in*, because a fuzzer's entire job is finding UB — and
ReleaseFast compiles out the safety checks that would catch it. A ReleaseFast
fuzz campaign can run for hours over corrupt input and report success while
silently exercising undefined behaviour.

Evidence: the fleet ReleaseSafe floor (2026-07-01, adopted fleet-wide
2026-07-29) immediately exposed three real crashers in `rarz` — where every
multi-file archive was **silently corrupt while reporting VALID** — and a `u32`
underflow in `tiffz` that had been producing the correct answer *by accident*
for months. Both suites were green under ReleaseFast.

### Storage

```
fuzz/findings/<seed>-<short-desc>/     # input that triggered it + repro notes
fuzz/corpus/                           # accumulated interesting inputs
fuzz/<machine-id>.ndjson               # campaign records
```

Campaign record fields: `seed`, `iterations`, `duration_s`, `optimize`,
`sanitizers`, `findings` (count), `commit`, `machine_id`, `when`.

- **Every crash becomes a permanent regression test** in `tests/` — that is the
  whole payoff. A fuzz finding that is fixed but not pinned will return.
- Corpus is source-controlled if small; otherwise generated from recorded seeds.

## Adoption

Not urgent, and explicitly **not** a reason to retrofit every project at once.
Apply when a project next touches its `bm`/`fuzz`, and to all new projects from
the start. Current state to converge:

- [ ] `jpegz` — has both; check field completeness (esp. `optimize`)
- [ ] `z7z`, `printable_binary` — have `bm`; align storage path + fields
- [ ] `validate` — has `fuzz`; align storage; it already uses ReleaseSafe there
- [ ] `jp2z` — `conformance/sweep.ndjson` predates this; align or document why
- [ ] `tiffz`, `rarz`, `rawz`, `random` — no `bm`/`fuzz` yet; add per this doc

## Open question for Peter

Promote this to a proper skill (`bench-fuzz`) so agents load it automatically,
or leave it as a policy doc referenced from the canonical brief? A skill gets
read; a doc gets forgotten — but the fleet already carries a
`zig-microbenchmarks` skill, and two overlapping skills is its own sprawl. My
lean: **keep this as the single language-agnostic contract, and have
`zig-microbenchmarks` reference it** for the Zig-specific mechanics, rather than
duplicating.
