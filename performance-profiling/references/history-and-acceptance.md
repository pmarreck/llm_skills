# History, policy and acceptance

Each project owns `profiling.json` with a stable project name and `history_url`.
The first engine uses an absolute existing writable `file://` directory. CLI
`--history-url` overrides `PERFORMANCE_HISTORY_URL`, which overrides that project
configuration. No daemon or database is needed. Network storage adapters are
future work; a file URL alone does not make a remote filesystem accessible.

Records are separate atomic one-line NDJSON files named
`<project>--<observation|approval>--<id>.ndjson`. Project namespaces do not overlap.
This avoids an append race; the reader supplies chronological history. Temporary
partial files never enter a baseline. Same ID/content is idempotent; different
content at that ID fails. Provision actual user/CI permissions, never world-write.

Keep measurement history outside the source repository to avoid invalidating
Nix's source/build cache on each observation. Build pinned adapters with Nix, then
run fresh measurements and storage outside its build sandbox/cache. Local and CI
must call the same implementation with the same policy. A cached successful
derivation is evidence of a previous run, not current host timing.

## Baseline and bounds

Freeze the accepted epoch and eligible reference IDs before measuring/appending.
The current value never enters its own baseline. Count only selected passing
top-level observations and explicit approval anchors; never recursively collect
numeric fields from diagnostics. Hardware cohorts include relevant CPU/features,
OS/architecture, toolchain/runtime, profile, concurrency, backend and measurement
method, plus GPU for GPU work. Source changes are provenance, not a new cohort on
every commit. Version benchmark definitions when semantics change.

Initial policy uses a configurable relative band (10%) and an SD factor (3):
the allowable half-width is the greater of those bands and an explicit absolute
floor. Gate both directions. These are starting policies to tune from evidence,
not universally validated thresholds or a claimed p-value. Record policy,
minimum count, window, actual count, mean, sample SD, bounds and comparison method.
High sample/historical variation is inconclusive. Declared shape/resource limits
remain independent of permissive statistical bounds.

A manually approved new epoch starts from its exact observation. Until enough
history exists for SD, it uses that approved anchor's percentage/absolute bounds
and records `approved-anchor-percent`; it does not invent sample variance from
duplicate rows. New hardware without approval stays `UNBASELINED`, exits nonzero
and records valid measurements for review.

## Single retry

An otherwise valid timing deviation/noisy sweep gets one complete retry with the
same executable, source, seed, sizes, reference snapshot and policy. First pass
is PASS. Fail then pass is PASS_ON_RETRY with only the passing selection eligible.
Two failures retain diagnostics and fail; no passing selection means no eligible
baseline row. Crashes, correctness, real leaks, protocol and storage failures are
not timing retries. Deterministic count/shape violations are not noise retries.

Nested failed attempts may contain full measurements but are diagnostic only.
Inspection can identify intermittent defects; this does not introduce another
automatic flakiness gate. Automatic CI retries and agent reruns cannot approve
changes. `accept --run ID --reason TEXT` records an owner-approved epoch, never
rewrites history. Do not auto-accept to make CI green. Conflicting concurrent
approvals from one parent epoch stop comparisons rather than pick a silent winner.

## Record provenance and evolution

Each observation/approval has a versioned schema, UTC ISO timestamp with
milliseconds, project/case/phase, units, raw measurements, selected result,
diagnostics, verdict, policy, cohort, reference IDs and epoch. Record uname,
runtime/build, exact argv, fixture/seed, executable/source identity and Git HEAD.
Collect dirty code paths with NUL-delimited Git queries and exact added/deleted
counts. Exclude dotfiles/dot directories and .ndjson/.toml/.txt/.md from those
code stats only; relevant config still belongs in reproducibility identity.
Git does not define a unique changed-line count. Binary line stats are unavailable.

Use the pinned printable-binary space-preserving encoder for path/argv byte
strings, storing its map hash/version. JSON serialization still handles the whole
record. Preserve argv boundaries and empty arguments. Never persist credentials
or whole environments; use non-secret references. Source/executable changes
during a sweep invalidate the observation.

NDJSON is framing, not a schema. Reject unsupported schemas or damaged required
records. Add explicit reader adapters/migrations when a real older format exists,
preserving originals and units/method versions. Do not guess missing baselines or
discard old failures. Storage failure is an error, never silent green.
