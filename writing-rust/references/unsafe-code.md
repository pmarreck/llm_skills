# Unsafe Rust

`unsafe` switches off the guarantees that make Rust worth using: memory safety,
data-race freedom and the absence of undefined behavior. The compiler stops
checking, and every invariant becomes a promise a human or agent must keep by
hand, forever, through every later edit. Treat each new `unsafe` block as a
liability that has to earn its place with evidence.

There are only two acceptable reasons to add it: a **measured** performance win
that the owner accepts, or an operation with **no safe equivalent** (FFI, a
platform intrinsic, a primitive the standard library cannot express). Anything
else gets removed.

## Make new unsafe a compile-time decision

Encode the policy in the crate so an omission fails early:

- A crate that needs no `unsafe` declares `#![forbid(unsafe_code)]` at its
  root. New `unsafe` then fails to compile, and `forbid` cannot be overridden
  further down.
- A crate that genuinely needs it declares `#![deny(unsafe_code)]` at its root
  and `#[allow(unsafe_code)]` only on the specific modules that hold the
  unsafe implementation. Adding `unsafe` anywhere else is a compile error, so
  the unsafe surface stays small and visible in review.
- Enable `clippy::undocumented_unsafe_blocks` where Clippy is configured, so a
  block without a `// SAFETY:` comment fails lint. In the 2024 edition,
  `unsafe_op_in_unsafe_fn` warns by default; keep it on so each unsafe
  operation inside an `unsafe fn` needs its own justified block.

## Performance-motivated unsafe: the required protocol

Never write the unsafe version first. For an optimization that might use
`unsafe` (a pooled allocator, unchecked indexing, transmutes, raw-pointer
traversal):

1. **Write it safely first.** Implement the fastest safe version you can, and
   leave comments where `unsafe` would help, saying what it would buy (bounds
   checks removed, an allocation avoided, aliasing the borrow checker rejects).
2. **Benchmark the safe version.** Use the project's benchmark harness through
   the shared `performance-profiling` skill, with realistic inputs.
3. **Write the unsafe version.** Keep it as small as possible, behind the same
   safe API, with a `// SAFETY:` comment on every block.
4. **Benchmark the unsafe version** with the same harness, inputs, machine and
   build profile.
5. **Choose on the measurements, keeping the other version alive.** Prefer
   keeping the version you did not choose compiled behind a non-default Cargo
   feature, with both paths under test (see the next section). When the two
   cannot share one interface, leave it commented out and intact beside the
   winner instead. Either way, record both measurements, the commit and the
   toolchain, and explain the compromise: what the unsafe version gains, what
   it risks, and why this choice won. Commented-out code is not compiled, so
   anyone reviving it must rebuild and re-benchmark first.

If the safe version is within measurement noise, or the gain does not matter at
the call site's real workload, choose the safe version. No measurements, no
`unsafe`.

## Choosing how much unsafe to lean on with Cargo features

Cargo features are compile-time flags: code gated with
`#[cfg(feature = "...")]` is only compiled into builds that enable the
feature, so the unused side costs nothing at run time. Reach for one when:

- keeping the rejected side of the performance protocol alive, where it stays
  compiled and can be re-benchmarked with one command instead of rotting as
  a comment; or
- an application genuinely needs to choose its own safety and speed trade-off
  per build, such as a hardened build next to a throughput build, or a
  platform where the unsafe path's invariants have not been verified.

Put both implementations behind the same public type or function, and make
the default build use the measured winner:

```toml
[features]
default = []
# Rejected alternative: unsafe pooled allocator. Record both measurements,
# the commit and toolchain, and why the default won.
unsafe-list-cell = []
```

```rust
#[cfg(not(feature = "unsafe-list-cell"))]
mod list_cell_safe;
#[cfg(not(feature = "unsafe-list-cell"))]
pub use list_cell_safe::ListCell;

#[cfg(feature = "unsafe-list-cell")]
mod list_cell_unsafe;
#[cfg(feature = "unsafe-list-cell")]
pub use list_cell_unsafe::ListCell;
```

Rules:

- **Both paths under test.** A gated alternative only stays alive if
  something builds and tests it. The project's `./test` and Nix checks must
  cover the non-default configuration too, for example a second check
  derivation with `buildFeatures` set. The benchmark harness must accept the
  feature so the comparison can be repeated, and Miri, where used, runs
  against the unsafe side.
- **One switching feature, identical behavior.** Use a single feature that
  selects the implementation, never a pair that must not both be enabled.
  Cargo unifies features across the dependency graph: if any crate enables
  the feature, every user of the crate gets it. That is harmless only when
  both implementations behave identically, so their tests must assert the
  same results. In a published library, one dependent's choice then applies
  to all of them; say so in the feature comment.
- **Name the feature after the non-default side** (`unsafe-list-cell` when
  safe wins, `safe-list-cell` when unsafe wins), so enabling it always means
  "use the alternative".
- **Many pairs: one global choice and an exhaustive registry.** When an
  application accumulates several safe/unsafe pairs, offer one selection
  that covers all of them, such as `--prefer-safe` and `--prefer-unsafe`
  build options that pick a side for every pair, while each pair otherwise
  uses the default its own measurements chose. Keep one registry listing
  every pair with its default side and feature name, and make the test
  suite fail when a declared feature is missing from it, so a new pair cannot
  ship unregistered. Coverage is then two builds, all-safe and all-unsafe,
  each exercising every pair at once.
- **Unsafe stays confined.** The unsafe module keeps its
  `#[allow(unsafe_code)]` under the crate-level `deny`, with `// SAFETY:`
  comments, whichever side is the default.

## Unavoidable unsafe: FFI, intrinsics and primitives

When no safe equivalent exists:

- Keep each block minimal and wrap it in a safe function or type, so callers
  never write `unsafe` themselves. The safe wrapper owns the invariants.
- Precede every block with a `// SAFETY:` comment stating exactly which
  invariants make it sound (non-null, aligned, initialized, exclusively
  borrowed, lifetime outlives the use, length in bounds) and where they are
  established.
- Document `unsafe fn` preconditions under a `# Safety` doc heading.
- At C boundaries, follow the pointer-plus-length, ownership and panic rules
  in the main skill.
- Test the boundary: the safe wrapper's contract, malformed input, and Miri
  (`cargo miri test`) where the code does not cross into foreign code it
  cannot interpret.

## Existing unsafe that predates this rule

Do not rip it out blindly. When you next change that code, or when the owner
asks, run the performance protocol retroactively: build the safe version,
benchmark both, and keep the loser commented out with the comparison. Until
then, make sure every block has a `// SAFETY:` comment and the module is
confined by `#[allow(unsafe_code)]` under a crate-level `deny`.

## Reporting

When you add or keep `unsafe`, say so plainly in your report to the owner:
which file, how many blocks, which of the two reasons above justifies it, and
the benchmark numbers if it was a performance choice.

## The advisory hook

`writing-rust/scripts/unsafe-advisory-hook` is a PreToolUse hook for Claude
Code and Codex. When an edit increases the number of real `unsafe` keywords in
a `.rs` file, it injects a strongly worded advisory that points back here. It
ignores `unsafe` inside comments, string literals and identifiers such as
`unsafe_code`, so the commented-out alternative this protocol requires does not
trigger it. It never blocks the edit: the owner chose advice over a hard gate,
because legitimate FFI work needs `unsafe`. Edits made through shell commands
rather than the agent's file-editing tools bypass it; the crate-level lints
above are the backstop.
