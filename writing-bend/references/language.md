# Language and exact arithmetic

Applies to the tested 2.0.37 generation. Read `bend guide` and `bend base` from
the selected compiler when a detail differs. The official
[guide](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/guide/GUIDE.md)
and [Base source](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/base.bend)
are navigation references, not substitutes for compiling the changed code.

## Syntax traps encountered in a substantial port

- Import `Base`; use explicit argument/result types. Annotate ambiguous
  operator expressions, for example `(a + b : U32)`, rather than relying on
  inference from another language.
- `42` is a U32 literal; `42n` is Nat. Signed or wider words are not built-in
  I64/U64 primitives in this generation.
- Constructors use braces, such as `Done{value}` and `Nil{}`. Pattern match
  multiple parameters with `match a b:` and corresponding paired patterns.
- Branch with `match` on a Bool. Put a computed scrutinee in a helper's
  parameter; the checker does not accept arbitrary computed matches. Also
  respect the checker's binder order: an intervening let can prevent a later
  parameter match. Refactor into a small eliminator rather than fighting it.
- Define live dependencies before their callers. Refactor mutual recursion
  into one structurally recursive dispatcher with an explicit mode if needed.
- `~` is compile-time specialization, distinct from erased `-` parameters and
  reusable `+` values. Do not make a closure copyable by pretending it is data.

## Affinity is part of the API

`Type` and `Data` correspond to different allowed use quantities. Lists and
results have quantity parameters; the short forms are not interchangeable
with every `Result<&2, &2, E, A>` or `List<&2, A>` signature. Read the actual
declaration in Base before inventing an annotation. A reusable error/result
requires reusable fields too.

An affine closure is consumed by a call, including a partial application.
Arrays likewise retain ownership across operations. For reusable first-order
data, use `is Data` and explicit `+` binders/pattern fields. For callback plans,
preserve single-use continuations rather than trying to duplicate them.

Binder quantities also affect higher-order signature compatibility. In the
forward trial, `def print_case(+word: U32) -> IO(Unit)` could not serve as
`List.for_each`'s affine `U32 -> IO(Unit)` callback. Keeping the parameter
affine and introducing `+value = word` inside the function allowed local
reuse without changing the callback's signature. Check the expected function
quantity when an otherwise correct callback is rejected.

## Termination and lazy decisions

Use a genuinely decreasing structural parameter, placed before parameters
that change arbitrarily. Numerical intuition such as "this eventually gets
smaller" does not establish the checker's structural subterm relation.

A byte-request tree whose continuation returns another tree is not necessarily
recognized as structurally decreasing. In one tested design, continuation-
encoded `Program(A)` made bind nonrecursive, while an interpreter consumed
explicit Nat fuel. That is an architectural option, not a claim that all
higher-order recursion must use that representation.

Give fuel exhaustion an explicit result and define whether it preserves a
completed source prefix. Multi-limb/lexicographic fuel can cover a domain that
does not fit one runtime Nat while retaining a structural decrease.
Do not introduce `@unsafe`, `def f?`, or a foreign
recursive worker to bypass termination in a supposedly proved core.

Ordinary function arguments are evaluated before the callee uses them in the
compiled execution path. Passing two already-computed alternatives to a Bool
selector can evaluate the failing or expensive branch too. Use a Bool-matching
helper with single-use `Unit -> A` thunks when only the selected action should
execute. Test error/source-consumption behavior, not only successful values.

## Numeric representation must match the target

The pinned native runtime represents Nat with a **48-bit payload**. Do not
treat the checker's mathematical Nat, or JavaScript's Number, as a portable
native bignum. The port used U32 limbs for 64-bit words, signed mantissas,
wide products and cursors; Nat was restricted to proved-small counters.
Reinspect the runtime before carrying that limit into a different release.

For bit-identical arithmetic:

- Declare limb order and signed/exponent encoding. A U32 holding an i32 bit
  pattern is not itself a signed exponent.
- Bound every intermediate, not just the final result. A 32×32 product can
  use 16-bit partial products with explicit carries; a naive U32 multiply
  loses information before a wider result is assembled.
- Specify shifts by zero, word width and larger widths explicitly. Check
  shift and division behavior in the selected Base/backend, not C intuition.
- Test negative rounding, overflow, near-zero cancellation, normalization,
  domain refusal and arbitrary-width codec canonicalization with an external
  integer or high-precision oracle. F32 is not an exact-math substitute.
- Separate magnitude from fixed-capacity cursor/admission domains. A wide
  decoded count does not authorize overflowing a caller's output capacity.

## Data structures are algorithms

The runtime's in-place array operations preserve pure ownership, but that does
not give ordinary C-vector bounds behavior. The pinned guide describes wrapped
array indexes and power-of-two capacities. Validate public indexes before
access when the contract calls for refusal. Use the actual Array API for
non-U32 elements and account for ownership returned by a read.

Large left-linear list lookups and deeply nested expressions can cost both
checker/normalizer time and runtime traversal. A balanced lookup tree worked
for a frozen 256-row table. Preserve a separately generated canonical table
and compare all rows; balancing must not alter constants or rejection order.
Likewise, list-based Fisher–Yates index plans can be quadratic. Purity does
not supply constant-time random access.
