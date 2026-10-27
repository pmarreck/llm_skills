# SIMD and vectorization opportunity review

Use this checkpoint during CPU hot-path profiling, throughput optimization and
performance reviews. Ordinary small edits do not require a vectorization audit.
The goal is to stop overlooking useful parallel computation while retaining
measurement and correctness as the acceptance criteria.

## Establish the opportunity before editing

1. Profile representative workloads in the actual optimized configuration.
   Identify time spent in the candidate and whether computation, memory traffic,
   I/O, allocation or synchronization limits the complete operation. Prefer
   eliminating unnecessary work and improving algorithms/layout where warranted.
2. Save a repeatable baseline with inputs, compiler/options, CPU features,
   dispatched implementation, thread count and warmup policy. Include small and
   realistic large inputs. Follow the main skill's measurement/history contract.
3. Inspect optimized assembly, IR or compiler vectorization remarks. Check
   dependency feature flags and runtime dispatch: a fast implementation may
   already exist but be disabled. A vector instruction alone does not establish
   useful acceleration, and an opaque library call is not evidence of scalar code.
4. Consider independent repeated arithmetic, comparisons, transforms, checksums,
   scans and byte processing. Serial dependencies, tiny inputs or memory bandwidth
   may limit gains. Record the reason if SIMD is inapplicable or deferred.

LLVM documents its loop and SLP vectorizers and diagnostic remarks in
[Auto-Vectorization in LLVM](https://llvm.org/docs/Vectorizers.html). For deeper
Zig code-generation work, use the existing `llvm-guided-optimization` skill.

## Choose and verify the smallest candidate

Try an existing accelerated library path, clearer vectorizable scalar code or
portable vectors before maintaining architecture-specific intrinsics, when those
options meet the requirement. Explicit intrinsics remain appropriate when they
produce a demonstrated improvement that simpler code does not.

Keep a scalar reference or another independent oracle. Differential tests must
compare results and relevant error behavior, not merely assert that neither path
crashes. Cover empty/short inputs, lengths around vector boundaries, non-multiple
tails, unaligned starts, malformed/truncated inputs and extreme values. Check
overflow, saturation, signedness, endianness and floating-point rounding against
the actual contract. Do not silently relax numerical accuracy for speed.

Never read beyond the valid input merely because a vector load is convenient.
Use bounded loads or a scalar tail; where appropriate, exercise protected-page
boundaries in isolated integration tests so readable neighboring memory cannot
hide overreads. Run the relevant sanitizers/fuzz regressions as well as the complete
correctness suite. Verify outputs are consumed during benchmarks so the compiler
cannot optimize away the measured work.

## Qualify dispatch and platforms

Keep a compatible baseline path. Detect required CPU features and OS support
before entering an optional ISA implementation; prefer the language/runtime's
supported detection facilities over an improvised CPUID check. Do not distribute
a host-native build as though every machine of the same architecture supports it.
AVX-family execution, for example, also depends on OS-enabled register state.

The [Rust architecture module](https://doc.rust-lang.org/std/arch/index.html)
documents architecture-specific intrinsics, target features and runtime detection
with a fallback. amd64 and arm64 require their own qualification; do not presume
an x86 gain transfers to ARM or that the widest vectors are always fastest.
Exercise each available path explicitly, including baseline dispatch. Never force
unsupported instructions to run. Cross-compilation alone is not runtime evidence;
record platforms or ISA paths that remain unqualified.

## Accept on evidence

Compare baseline and candidate with equivalent inputs, optimization settings,
thread counts and setup. Use repeated, preferably interleaved measurements to
expose drift and noise. Report both kernel and complete-operation timings; a
threefold kernel gain does not imply a threefold application gain. Include dispatch
overhead on small inputs, memory usage and code-size costs when material.

Retain the candidate only when correctness holds and repeatable gains justify
maintenance on intended targets. Reject a noisy or negative result rather than
loosening acceptance bounds. A valid platform-specific improvement may warrant
dispatch instead of replacing every platform's implementation.

Keep a short durable result with the benchmark command, input identity, platform,
compiler/options, chosen path, before/after measurements and correctness checks.
Label kernel-only, single-machine and reported-but-unverified gains accurately.
Use the existing external measurement history instead of creating a second
logging scheme. Required bounded regressions remain reachable through `./test`.
