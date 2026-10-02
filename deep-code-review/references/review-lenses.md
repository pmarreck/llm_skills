# Review lenses

Read only applicable sections. These are prompts for contract investigation,
not automatic findings. Establish reachability, impact and evidence before
recommending a change.

## Functionality and cross-layer contracts

Compare documented intent/public promises with entrypoints, flags and variants.
Check stubs, skipped work reported as success and differences between similar
paths. Trace input admission, core behavior, errors, ownership and final effects
across modules. Intentional deferral is not a broken shipped promise unless
users are told the feature exists.

For decoders, distinguish corrupt data from unsupported variants and resource
limits; verify that callers retain error types and located byte/bit/block details.
Check streaming and bounded-memory claims at actual consumer pins and variants,
not just the existence of a reader-named API.

## Behavioral coverage and meaningful controls

Check success and failure boundaries: empty/minimal/maximal input, malformed
Unicode, overflow, truncation, cancellation and allocation/adapter failure.
Preserve cheap exhaustive domains, relevant corpora and justified statistical
samples. Count unsupported/skipped cases and reject a vacuous zero-case pass.

For reversible mappings, declare source/target sets; test both inverse directions,
uniqueness, coverage and agreement with the specified mapping. Two mutually wrong
inverses can round-trip. For normalization/lossy transforms, test canonicalization
or loss bounds instead. Continuous samples, including boundaries, are evidence
with stated numerical tolerances, not proof of bijectivity.

Look for assertions on setup rather than behavior, self-generated expectations,
unreviewed snapshots and success-only checks that accept wrong answers. Prefer
a negative control or mutation witness showing the test can fail for the relevant
defect. Corruption detectors need known-valid specificity cases so rejecting
everything cannot score perfectly; separate must-detect mutations from those a
format can legitimately ignore.

Keep every required subtest/gate in one complete default test entry point.
Integration work must not become an optional forgotten suite. Favor isolated
tests of the functional core, with a smaller real-integration layer. Approximate
90/10 is an architectural target, not a reason to delete necessary coverage.
Inject clocks, random sources and I/O through per-test state-collecting adapters;
assert returned values, recorded effects and error outcomes. Avoid incidental
logging assertions for core behavior. Check actual bytes/rendering/CLI status
in focused adapter tests when those are the contract. Fakes must not duplicate
business logic or substitute for real file/network adapter evidence.

Avoid sleeps, external-service dependencies, shared mutable fixtures and unnecessary
disk/network use. Bound parallelism by CPU/memory/I/O needs; give real-I/O integration
cases private temporary resources. Selected runs help iteration but cannot establish
full acceptance. Long benchmark/fuzz experiments may have separate commands;
required bounded gates/regressions still run through the complete suite.

## Idempotency, concurrency and recovery

Test interrupted retries around each effect/checkpoint boundary with the same
logical identity. Check stale markers, crash-after-effect/before-ack windows and
a completed rerun being a no-op. Look for stable operation IDs, atomic updates,
durable replay evidence, rollback and safe resume; an “exactly once” claim needs
a supporting contract.

Unconfirmed email/SMS/UDP delivery may be repeated under an explicit bounded
policy. Duplicate notification tolerance does not permit duplicate charges/grants
or unrelated state transitions. Preserve message/token identity where appropriate;
uncertainty alone is not permission to invalidate an existing token.

Check overlapping retries, TOCTTOU, lock order, atomic read-modify-write, queue bounds,
backpressure, cancellation and shutdown. Inject schedules/failures instead of
relying on lucky sleeps. Test interrupted writes/replacements with recoverable
originals and no production data.

## Complexity and resource budgets

Identify input dimensions and hot paths: nested scans, repeated string growth,
query count, allocations, caching and decompression amplification. Distinguish
unavoidable work from avoidable asymptotic cost. Measure consequential proposals
under comparable optimized builds with correctness checks and defined workloads.

Use the shared `performance-profiling` skill for measurement, growth, memory and
history contracts. Inspect whether the actual checks establish correct work,
cover meaningful input dimensions and reach the complete suite. Do not mandate
a benchmark for every loop or shrink a correct exhaustive test for its count.

Review peak/retained memory, stack bounds, descriptors and per-worker buffers under
realistic concurrency. Allocator choices depend on lifetime, failure behavior and
measured workload; page/arena/heap/stack use alone is not a defect.

## Ownership, memory safety and FFI

Trace custody through acquisition, transfer, failure and cleanup. Check use after
free, double free, temporary slices, aliasing, allocator mismatch and partial
initialization. Same-scope cleanup helps unless ownership is explicitly transferred.
Use leak-aware allocators/sanitizers for failure tests where available.

Across foreign-language interfaces, inspect sizes/alignment/calling convention,
null policy, lengths, encoding, buffer capacity, ownership, callbacks, concurrency,
panic/exception behavior and error/result lifetime. Pointer-plus-length can be
correct; sentinel termination is required only when the ABI requires it. Check
parallel result builders and error-definition drift. Batch calls only when
overhead is demonstrated and the contract permits it.

Inspect actual built symbols/linkage before claiming export leakage. Zig uses
`export`/`@export` for external symbols; `pub` governs import visibility. Verify
APIs against the project's compiler version, including cleanup/I/O signatures.
[Zig 0.16 Functions](https://ziglang.org/documentation/0.16.0/#Functions),
[@export](https://ziglang.org/documentation/0.16.0/#export).

Do not prescribe C `alloca` as a generic ownership improvement. It uses the caller's
stack; overflow has undefined behavior. Justify bounds/lifetime first. `strncpy`
may produce non-null-terminated, null-padded data; check lengths, capacity,
termination and truncation. `snprintf` also needs return-value/truncation handling.
[alloca](https://man7.org/linux/man-pages/man3/alloca.3.html),
[strncpy](https://man7.org/linux/man-pages/man3/strncpy.3.html).

## Security and errors

Identify trust boundaries: authentication, authorization, capabilities, secrets,
untrusted paths/URLs/archives, command construction and attacker-controlled sizes.
Check injection, traversal, symlink races, arithmetic, resource exhaustion and
fail-open decisions. Inspect key roles, signatures, expiry/replay/rollback,
dependencies and release/update trust where relevant. Review authority does not
permit intrusive probes or unrelated secrets.

Check swallowed errors, unproven unreachable claims, partial success, lost causes
and missing context. Broad error types or ignored errors need contract analysis,
not an automatic warning. Preserve structured types/locations across layers.
Expose useful public diagnostic codes without secrets or sensitive inputs; redact
internal logs too. Recover/refuse at a safe boundary instead of aborting an
in-flight transaction merely to be “loud”.

## Database and durable state

Inspect transactions, constraints, concurrent upserts, idempotency keys,
query multiplication/N+1, unbounded scans and query/index evidence. Check
parameterization, authorization and time-zone/money representation. Verify
migrations/backfills against interrupted/repeated runs, compatibility needs,
backups and recovery. Forward-only migrations may be deliberate; establish
recoverability rather than demanding a destructive down migration. Test relevant
real-engine behavior in isolated integration fixtures; mocked queries cannot
establish transaction/constraint semantics.

## Packaging and operating behavior

Trace configuration precedence, invalid settings, default bounds, native dependencies,
platform paths, clean-build inputs, CI targets and shutdown/logging. File presence
or cross-compilation is not native runtime proof. Respect package-manager ownership
(for example, do not mutate Nix-store installs). Verify signed-target reconstruction
and update replacement recovery without publishing a release during review.

## Maintainability and language idioms

Use duplication, nesting, naming and file length to locate unclear contracts;
report concrete cost rather than arbitrary line counts or fashionable features.
Check dead-code reachability across generated callers, callbacks, exports and
external consumers. Avoid premature abstraction for merely similar code. Preserve
compatibility for actual users/persisted data rather than hypothetical users.

Verify Zig/C/Rust casts, layouts and error/ownership mechanics against the actual
toolchain. For Nix, inspect reproducible inputs, Git source visibility, runtime
closures and outputs rather than style alone. For LuaJIT, inspect allocation
pressure and buffer/FFI lifetime in measured hot paths; `string.buffer` or pointer
reads are candidates, not universal speed guarantees. Reuse standard facilities
where they meet the contract; document why a local implementation is needed.
