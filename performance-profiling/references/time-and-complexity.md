# Time and input growth

During implementation, ask of each function: **Is this on a hot path?** For a
one-off operation, a theoretically suboptimal complexity is usually an
optimization-pass concern. Once a hot-path function first works correctly,
record an optimistic complexity estimate and add it to `./big_o`; later
measurements can refine the estimate. Do not wait for an optimization pass to
protect an important path from an obviously explosive algorithm.

For each declaration, state the expected model, meaningful input dimension(s),
and fixture distribution. Sweep N, 2N, 4N, 8N while holding other dimensions
fixed; multi-input algorithms need separate axes or representative joint sweeps.
Cover adversarial and typical distributions. Version cases/fixtures and record
seeds, iterations and raw samples. The gate must fail if a hot-path declaration
has no measurement, a measurement has no declaration, or a declaration is stale
or unexercised. An annotation not discovered and enforced by the runner is not
a gate.

For Rust projects, consider the pinned `big_o` crate as the inference and
model-bound adapter. It fits measured sizes to candidate models, reports
confidence and warnings, and supports upper/lower model assertions. The crate
does not discover hot paths or force registration, so `./big_o` must still
discover declarations and enforce completeness. Other languages should emit a
shared versioned declaration protocol; use structured metadata when the
language lacks a suitable annotation mechanism. Identify functions by stable
operation key plus source location, not line numbers alone.

Preserve every adjacent growth ratio. `[2,4,2]` has a median of 2 and an important
crossover; never gate only that median. Deterministic operation counts can provide
cheap portable controls when their coverage is explicit. Validate results against
an independent oracle/invariant so skipped work does not look like optimization.

Constant, linear and quadratic work ideally double by 1, 2 and 4. N*log2(N)
doubles by `2*(log2(N)+1)/log2(N)`, only 2.2 at N=1024 and 2.125 at N=65536.
A 10% interval does not generally separate linear from N*log(N). Timing sweeps
cannot establish an asymptotic theorem. A 2.8 cap is a declared practical bound,
not universal proof of linearity. Finite sweeps can still enforce a useful,
falsifiable operating contract over declared workloads.

Machine speed cancels only when it acts as one constant multiplier at all tested
sizes. Caches, allocator thresholds, SIMD, NUMA, frequency and I/O can break that
model. Record hardware/runtime/backend context and compare compatible histories.
Store transient load/thermal/frequency evidence separately from stable cohort identity.

## Measurement phases

1. Prepare/generate the fixture before the timed kernel.
2. If warmup is part of the workload, feed an explicit prefix Z through the
   same code path before timing. Record Z and whether complexity is in timed
   suffix size n (holding Z fixed) or total processed size N=Z+n. Measure
   scaling setup separately when it is user-visible or grows with input.
3. Warm the actual code inside its process; discard warmup samples and label
   cache state as cold, warmed or a defined mixture.
4. Measure repeated verified work with monotonic wall and process/thread CPU clocks.
5. Check the output/work invariant outside the timed region.
6. Teardown and check ownership separately.

For a presumed linear steady-state model `T(n)=b(n+Z)`, a fitted line
`T(n)=a+bn` implies `Z=a/b`; the x-intercept is `-a/b`. This estimate is valid
only when the linear model and fixed-offset interpretation fit the data. For
nonlinear models, fit an explicitly shifted form only when justified, and
validate it on held-out sizes. Never infer a warmup amount from the y-intercept
alone or from only three tail measurements. A geometric size ladder is useful
for detecting regime changes; a sparse decade sweep can reveal broad changes
but needs more points near any bend. A bend is evidence of a regime change, not
proof whether cache, buffer, allocator or algorithm behavior caused it.

Run timing cases at a declared core count: single-core (1) and multicore (12
by default), as separate cases with separate cohorts. Pinning also keeps other
work on a busy host off the measured CPUs only partly: pick the CPU pool
(`PERFORMANCE_CPUS`) away from known heavy jobs, and treat a noisy sweep as
inconclusive, never as a shape result.

CPU time is useful for single-threaded compute. Wall time answers user-visible
parallel/I/O duration; multi-threaded CPU time sums work across threads. Record
which clock and thread/process scope was used. Keep repetitions long enough for
clock resolution, record aggregation and sample spread, and report excessive
noise as inconclusive. Do not hide noise with an unbounded best-of search.

Record fixed-workload absolute timing and input growth as distinct series; one
does not replace the other. Startup-to-ready is an absolute phase with a defined
ready marker, no input-growth ratio. The shared adapter can time process spawn to
receipt of that marker, separately from in-process kernel samples. Record that
IPC/scheduling boundary. An in-process entry-to-ready duration must disclose that
it excludes interpreter/loader startup. Cold first work is another useful case.

`hyperfine --shell=none --warmup N` is useful for whole-process measurements;
include hyperfine in the flake if used. Its empty-shell calibration cannot remove
the application's startup cost. Do not subtract an unrelated no-op duration,
clamp negative residuals, or force a global governor/cache/ASLR change unasked.

Use optimized shipping builds for performance, and separate safety-enabled
profiles for correctness/UB checks. An optimized test cannot substitute for a
ReleaseSafe/sanitizer check. Assert that a debug banner/profile is absent rather
than merely hiding its stderr. Debug CLI builds announce themselves to stderr.

References: [Google Benchmark](https://google.github.io/benchmark/user_guide.html),
[variance guidance](https://google.github.io/benchmark/reducing_variance.html),
[Hyperfine calibration](https://github.com/sharkdp/hyperfine#shell-startup-time).
