# Measured implementation lessons

## Measure the boundary you intend to recommend

An emitted C file does not imply C-like speed for an arbitrary algorithm.
U32 limb algorithms, graph allocation, byte-request interpretation, repeated
preparation and missing read-ahead remain runtime work. Proof checking is a
build/check cost, not an explanation for every runtime slowdown.

Distinguish checker normalization, JS, native executable, embedded C ABI and
whole-CLI timing. A value-returning `main` can run through normalization;
compile optimized native code for runtime measurements. Include the caller's
real setup/output work when measuring startup or end-to-end CLI behavior.

Keep CPU and monotonic wall time separate, prove nonempty equivalent work,
and record state/cursor consumption. A workload fold can detect errors but
is not a collision-resistant proof; use complete digests and exact states in
separate preflight where appropriate. Avoid writing payloads to disk.

Measure single-core and multicore availability separately. The studied
serialized library did not demonstrate useful speedup with twelve CPUs;
that does not establish the limit of a balanced native/GPU Bend program.
JS execution is sequential in this generation. Parallelizing rejection draws
can change byte consumption and therefore the deterministic contract.

## Preserve comparison qualifications

The full RNG case study used actual public APIs with different buffering,
runtime and preparation costs. At its largest normal workload native Bend
cost about 11.56 microseconds/value versus Zig 64.54 ns and Rust 56.26 ns.
That is evidence about those implementations/APIs, not a language ceiling.
See the [retained full evaluation](https://github.com/pmarreck/random/blob/c5bf5d56f2d745db502bb80ee52ef6ec7125fdfb/docs/reports/2026-10-20-bend2-full-evaluation.md).

Candidate optimizations include caller-owned deterministic read-ahead,
amortized prepared parameters, balanced lookup, better wide arithmetic and
bounded batches. Measure them individually against unchanged output/rejection/
error-prefix contracts. SIMD fallback and actual SIMD execution are different
claims. Do not call an unmeasured optimization a result.

## A Bend specification with Zig kernels

Two useful designs are a Bend model/oracle for a separately shipped Zig
implementation, or a Bend application with selected hot kernels behind a
foreign boundary. Choose from measured whole-application costs and required
proof scope; the current RNG result does not mean every Bend application has
the same slowdown.

First state and prove meaningful Bend obligations about the algorithm. Freeze
the input/output representation and failure/state semantics. Then implement
the Zig kernel and compare independent vectors, intermediates, boundary/error
cases and generated cases against Bend. Preserve byte consumption and rejection
order for sequential algorithms. Prove cross-language refinement where the
assurance requirement calls for it.

If a breaking algorithm change is authorized, version the construction/state
contract and freeze new independent expectations. Do not preserve old vectors
by weakening the new contract, or claim unchanged parity for a changed stream.

A handwritten translation does not inherit Bend's theorem. Differential tests
provide finite implementation evidence; they do not prove that every Zig run
refines the Bend model. Restricting a DSL and verifying its translation is a
separate possible project, not something this workflow has already achieved.

In a mixed runtime, use bounded bulk calls where measurement supports them.
Repeated scalar crossings can erase a kernel's gain, and marshalling, ownership,
callbacks and native-runtime failure behavior remain part of the contract.
The foreign kernel itself is outside a pure Bend proof unless explicitly
modelled and connected by a checked refinement or stated trust assumption.

Measure complete application code generation, native compilation and proof
checking separately. A small Core-only compile timer is not the full library's
build cost. Warm-toolchain observations do not measure a cold install or its
runtime closure size.

For benchmark infrastructure and historical acceptance, follow the project's
profiling contract. Preserve noisy and invalid records. A hard outer deadline
can invalidate an otherwise correct adapter; changing admission requires a
separately identified experiment, not a silent rerun or a baseline approval.
Do not retry noisy-only cases until they look favorable.

## Verify the statistical observation model

The shared custom-normal CLI rounds to integers even though the core can
return an unrounded fixed value. Treating its output as a continuous normal
produced an apparent SD discrepancy. For the studied round(N(5,2)) example,
the ideal integer-threshold CDF is Phi((k+0.5-5)/2), and a high-precision
numerical variance reference is approximately 4.083333333333333.
That reference is not an exact universal "variance plus 1/12" theorem.

Check whether a port or its test is actually wrong before changing a sampler.
Retain the failed analysis. A corrected same-sample interpretation is
exploratory/post-diagnostic; nominal IID envelopes do not restore post-selection
coverage. An inspected prefix, its extension and an unrounded run of the same
seed overlap. A separately predeclared holdout must not be pooled into an
undeclared overall confidence claim. Checking seven CDF points does not measure
the full empirical-CDF supremum, prove IID or certify cryptographic security.

Validate analysis inputs too. In LuaJIT, `#array` does not prove density and
`ipairs` stops at the first hole. The statistical helper initially accepted
sparse count/value arrays. Raw positive-integer keys with count equal to the
maximum index established a dense domain before numeric `rawget` traversal.
Known-good fixtures and wrong-law/malformed-input controls prevented a trivial
reject-everything repair from passing.
