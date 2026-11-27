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
5. **Choose on the measurements, keeping the other version.** Leave the version
   you did not choose commented out and intact beside the winner, with a
   comment giving both measurements and explaining the compromise: what the
   unsafe version gains, what it risks, and why this choice won. Commented-out
   code is not compiled, so record the commit and toolchain it was measured
   against; anyone reviving it must rebuild and re-benchmark first.

If the safe version is within measurement noise, or the gain does not matter at
the call site's real workload, choose the safe version. No measurements, no
`unsafe`.

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
