# Test execution and feedback latency

Owner-approved policy, October 20, 2026. Validate is the first pilot; shared
instrumentation and hooks are not yet claimed deployed. Measure before expanding
this to other projects. Extend the existing performance_profiling engine rather
than creating a separate general history or benchmark system.

## Budget and attribution

The complete test execution targets one second and has a five-second budget on
declared development hardware with dependencies available. Build/compilation is
excluded from that execution budget and measured separately. Also record total
invocation-to-result time so an expensive build remains visible. Document justified
project/hardware exceptions; agents cannot silently widen budgets.

Fixture reads and preparation, test process startup and runner overhead count as
execution. Do not hide them in compilation. Separate dependency acquisition,
queue waiting, Nix evaluation, compilation, actual execution and result delivery
where evidence permits. Unknown phases remain unknown, never zero. If a combined
build/test operation cannot be separated, label its timing mixed and do not claim
it meets the execution budget.

A cached Nix check is evidence of earlier correctness, not freshly executed tests.
Reusing compiled artifacts is useful; fresh test-runtime claims require executing
the tests. Keep cold setup, clean builds and warm/incremental runs distinct.

Use monotonic durations and UTC chronology. Record the revision/tree, test
inventory, executed/skipped counts, build profile, cache state, concurrency and
relevant host load. Do not time correctness suites only in a faster profile that
disables required safety checks. Preserve end-to-end instrumentation overhead.
For concurrent spans, use interval unions/critical paths for elapsed waiting;
summed worker time is a different resource metric. Never count overlap twice.

## Consequences without reducing correctness

Report correctness and latency independently. An over-budget suite should finish
its checks and produce an actionable timing failure/warning; five seconds is not
a kill deadline. Keep separate, bounded hang timeouts and descendant cleanup.
Incomplete or skipped required checks cannot count as complete success.

Before adopting a blocking CI gate, measure its real baseline and validate the
integration. Over-budget pilot observations must stay visible during this phase.
Historical comparisons retain the shared cohort, retry and explicit approval
rules. A rerun does not approve slower tests or normalize lost work.

Prefer batching cases within one process, isolated pure-core tests, injected
clocks/RNG/I/O and bounded concurrency. Retain real adapter tests where actual
filesystem, process, network or ABI behavior is the contract. Keep one complete
./test entry point; selected tests are editing aids, never a complete result.
Do not optimize by skipping assertions, weakening expected results, deleting
required cases or reusing cached verdicts while claiming execution.

## Decoder fixtures and storage

Minimize fixtures against a named behavior, not merely format validity. Retain
the features and boundary transitions that exercise the bug or requirement:
multiple blocks/frames/tiles, dictionary growth, checksums, offsets, overflow,
resource limits and corruption late in the payload may require larger data.
Verify decoded output and diagnostic behavior independently; demonstrate that
relevant deliberate defects remain detectable. Keep real-world clean-file
false-positive controls and preserve original corpus evidence recoverably.

Check existing representations first. Zig @embedFile already embeds file bytes
at compile time. Hex or printable-binary literals can improve reviewability but
are not automatic speedups; prefer compile-time decoding when practical and
measure compilation, executable size and runtime conversion overhead separately.
Embedding moves data into the executable; it does not eliminate cold executable
loading or justify removing file-backed adapter tests.

Compare equivalent work using file-backed, warm-cache, private tmpfs and
in-memory inputs where useful. Distinguish logical reads from physical device
traffic. ZFS ARC/page-cache effects and concurrent traffic limit attribution;
do not call a warm read a disk-speed benchmark. No machine-wide cache flushing
or direct-I/O substitution merely to manufacture a cold-cache result.

## Agent-visible feedback

Produce a concise status with correctness, latency, budget, comparable baseline
delta and largest measured costs. Detailed first/new/worsening violations and
bounded repeated reminders should drive investigation. Inject time and previous
notification state into a pure debounce decision; suppressing repeat messages
must not suppress durable observations or change the job's exit status.

Use stable job identities to connect submission, queue, start, completion and
delivery. Track cumulative waiting without double-counting parallel jobs.
Avoid redundant full-suite runs when an already-authorized run can supply the
same trustworthy measurements. Measure instrumentation cost itself. Do not log
secrets, whole environments or private endpoints in public artifacts.
