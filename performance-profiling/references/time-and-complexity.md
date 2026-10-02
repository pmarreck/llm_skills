# Time and input growth

Declare the intended work/complexity and meaningful input dimensions. Sweep
N, 2N, 4N, 8N while holding other dimensions fixed; multi-input algorithms need
separate axes or representative joint sweeps. Cover adversarial and typical
distributions. Version cases/fixtures and record seeds, iterations and raw samples.

Preserve every adjacent growth ratio. `[2,4,2]` has a median of 2 and an important
crossover; never gate only that median. Deterministic operation counts can provide
cheap portable controls when their coverage is explicit. Validate results against
an independent oracle/invariant so skipped work does not look like optimization.

Constant, linear and quadratic work ideally double by 1, 2 and 4. N*log2(N)
doubles by `2*(log2(N)+1)/log2(N)`, only 2.2 at N=1024 and 2.125 at N=65536.
A 10% interval does not generally separate linear from N*log(N). Timing sweeps
cannot establish an asymptotic theorem. A 2.8 cap is a declared practical bound,
not universal proof of linearity.

Machine speed cancels only when it acts as one constant multiplier at all tested
sizes. Caches, allocator thresholds, SIMD, NUMA, frequency and I/O can break that
model. Record hardware/runtime/backend context and compare compatible histories.
Store transient load/thermal/frequency evidence separately from stable cohort identity.

## Measurement phases

1. Prepare/generate fixture before the timed kernel.
2. Warm up the actual code inside its process; discard those samples.
3. Measure repeated verified work with monotonic wall and process/thread CPU clocks.
4. Check the output/work invariant outside the timed region.
5. Teardown and check ownership separately.

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
