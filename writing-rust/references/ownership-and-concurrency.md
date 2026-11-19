# Ownership, concurrency and panic traps

Compilation proves Rust's checked invariants, not good ownership boundaries,
bounded copying, concurrency throughput, or appropriate failure behavior.
Resolve these choices during implementation, not as deferred cleanup after a
borrow-checker workaround becomes the application's architecture.

## Review the operation, not its spelling

| Trigger | Required reasoning and preferred alternatives |
| --- | --- |
| `state.users.clone()` | Inspect the actual type. Cloning a `Vec`/map may copy every element; nested values can add allocations. Borrow, iterate, select the needed values, or transfer ownership when possible. An intentional snapshot is valid when its size, frequency and consistency are acceptable. |
| `Arc::clone(&users)` | Shares ownership without cloning the underlying collection. The reference-count update has a cost but differs fundamentally from a deep copy. Use an immutable shared snapshot when it fits; `Arc` alone does not make interior mutation safe. |
| `Arc::new(Mutex::new(db))` | Establish the database driver's concurrency model. A mutex around one connection may be necessary and correct, but serializes access. Consider an existing pool or a dedicated connection owner only where workload and driver semantics justify it. Do not mechanically substitute `RwLock`, a pool, async mutex or actor. |
| `db.lock().unwrap().get(id).unwrap()` | Separate lock acquisition, lookup and failure semantics. Not-found may be an ordinary `Option`; storage failure belongs in `Result`. Mutex poisoning can indicate inconsistent state: propagate or apply a justified recovery policy instead of blindly recovering or panicking. |
| Cloning to release a lock | Often useful when copying a small result permits expensive work after unlocking. Compare that cost with holding the lock; do not clone an entire store for one lookup. |
| `async fn` doing blocking work | Async syntax does not make synchronous database calls, filesystem I/O or heavy CPU work nonblocking. Use the driver's intended execution model, bounded blocking execution or another suitable boundary. |

For a new shared resource, answer: who owns it; what operations need atomicity;
how long a guard can live; what happens under concurrent load; and how failure
reaches the caller. A short local explanation or review note is sufficient for
non-obvious decisions. Avoid repetitive comments on routine handle clones.

Keep ordinary mutex guards within a small lexical block. Do not hold them
across `.await`, callbacks, rendering, or unrelated I/O. An async mutex may
deliberately span `.await` when exclusive ownership of an I/O resource requires
it; document that boundary and its serialization cost. An uncontended ordinary
mutex around short in-memory operations can be appropriate even in async code.
Bound spawned work and queues where input can grow without limit.

Prefer explicit typed operations on a resource-owning object over exposing a
public mutex that lets arbitrary callers retain its guard. Preserve required
transactions/atomicity when narrowing locks. Do not solve contention by
creating stale, independently mutable copies of authoritative state.

## What Clippy can enforce

Clippy is separate from rustc's default lints. Run it explicitly with the
project's pinned toolchain through the Nix-controlled complete test entry point.
Verify lint availability and select features/targets intentionally.

- `clippy::unwrap_used` and `clippy::expect_used` identify panic shortcuts.
- `clippy::await_holding_lock` identifies certain non-async guards retained
  across `.await`; it is not a general deadlock or contention detector.
- `clippy::clone_on_copy` catches cloning `Copy` values. It does not catch an
  expensive, semantically valid collection clone.
- `clippy::redundant_clone` can find unnecessary ownership duplication, but is
  a nursery lint; evaluate it with the pinned toolchain before adoption.

For new application-owned production code, prefer denying unwrap/expect and
await-holding-lock via crate or workspace policy. Scope justified exceptions
narrowly: tests may unwrap fixture construction, and proven programmer
invariants can warrant a panic with an explanation. Do not replace flagged
calls with indexing, `panic!`, ignored errors, fabricated defaults, or broad
`allow` attributes. Not every panic is detected by these three lints.

An example crate-level policy, adopted deliberately rather than injected into
unrelated crates:

```rust
#![deny(clippy::await_holding_lock)]
#![cfg_attr(not(test), deny(clippy::unwrap_used, clippy::expect_used))]
```

Integration tests are separate crates and need their own policy if desired.
These attributes take effect when Clippy runs. Existing-code adoption should
inventory violations and preserve coverage rather than disable the full gate.

No standard lint can decide that an arbitrary `Arc<Mutex<Db>>` is the wrong
architecture. Review ownership and failure paths, then measure hot-path
allocation, input scaling and contention using `performance-profiling`.
Use targeted behavior tests where needed for missing records, storage errors,
concurrent updates and preservation of authoritative state. Avoid tests that
merely assert the absence of the words `clone` or `Mutex`.

## Primary references

- [Clippy lint catalog](https://rust-lang.github.io/rust-clippy/master/index.html)
- [Tokio: choosing a mutex and owning I/O resources](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html#which-kind-of-mutex-should-you-use)
- [Arc shared ownership](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [Standard mutex poisoning](https://doc.rust-lang.org/std/sync/struct.Mutex.html#poisoning)
