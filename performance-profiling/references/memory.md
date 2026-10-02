# Memory growth and cleanup

Use a tracking allocator/adaptor to collect requested live bytes, peak live bytes,
total requested bytes and allocation count. State coverage: language-managed
objects, a specific native allocator, selected FFI allocations or whole process.
Counters must not imply broader coverage than they have. Keep allocator/runtime,
target pointer width, profile and concurrency in the measurement identity.

Run input-doubling sweeps for relevant memory metrics. Gate growth and unexpected
reductions under the common history policy after independent output verification.
Record all size/sample sets, not just the biggest RSS value.

For leaks, repeat a fixed workload through complete lifecycle/cleanup cycles after
warmup in one process. Record residual live requested bytes after every cycle.
Zero unowned residuals or a declared, bounded cache allowance is a stronger check
than comparing leaks with a rolling average. State cache ownership and eviction
expectations. Genuine leaks fail regardless of how frequently they occurred before;
they do not get an acceptance epoch or a timing-noise retry.

RSS/native working set is supplemental telemetry. An allocator can retain pages
after freeing objects, so elevated RSS alone is not an object leak. Conversely,
language allocation counters can miss leaking native FFI buffers. Use relevant
native instrumentation or sanitizers and preserve those checks in `./test`.

Dependency-inject allocation recording where practical without exposing test-only
branches in the kernel. Track each allocation/reallocation/free boundary and
failure cleanup; do not treat an arena/page/heap/stack choice itself as a defect.
Assess per-worker buffers and realistic concurrency as well as a serial case.
