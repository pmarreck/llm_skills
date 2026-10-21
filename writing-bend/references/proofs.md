# Proofs and verification

## Keep the claim independent of its implementation

State meaningful requirements in `LAWS.bend`, importing the real implementation.
Fill them from `PROOF.bend` with qualified definitions such as
`def Laws.word_size(word):`. The ordinary gate is `bend PROOF.bend`; it needs
both successful status and the expected `ALL PROOFS CHECK` receipt. An open
claim, unsafe dependency, diagnostic goal or failed compile is not success.

Examples use definitional equality `{==}` where reduction actually closes the
claim. More involved proofs may need case analysis, induction, equality motives
and `%` rewriting. Bend 2 is not Lean tactic syntax. Start with a law directly
about the executable function, not a toy model that the runtime never calls.

Protect a reviewed specification independently. The author should not quietly
weaken a law, shrink its domain or replace its predicate to fit broken code.
A frozen-specification digest is a useful review sentinel, not a proof that
the specification itself expresses the intended property.

## Ordinary checker and verdict kernel are distinct

`bend PROOF.bend --verdict` adds translation into BendTT and checking with its
separate Lean-backed kernel. Pin the compatible kernel and its Lean toolchain
as well as the Bend compiler. In the studied release the kernel used Lean
4.34.0; a project's unrelated Lean package need not be upgraded to that version.
An offline/hermetic test should provide an already-built `BENDTT` executable
through its derivation. Do not allow a missing kernel to trigger an unreviewed
installer, download or silent ordinary-only success.

The primary implementation is
[safe.ts](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/safe.ts);
the kernel and its own theorems are in
[bendtt.lean](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/bendtt.lean).
The frontend/parser and translation are not thereby proved correct, and the
kernel checks translated terms rather than a shipped C binary. Modelled native
operations, F32, foreign effects, runtime allocation and backend code generation
have their own assumptions or exclusions. Audit those before expanding a claim.

## Positive and negative controls

First establish that the unchanged implementation passes. Mutate isolated
copies so that a specific executable property becomes false, then require
the intended checker refusal. A timeout, absent import or missing kernel is
an infrastructure failure, not a successful mathematical negative control.
Restore nothing in the live source: mutate a private copy from the outset.

Also mutate a protected specification in a private copy and verify its sentinel
fires. Implementation mutations and specification mutations test different
control boundaries. Check compiler status as well as markers; never accept an
error run merely because it happened to print a desirable substring.

## Scope the final statement

A length theorem can prove four output elements without proving their content.
A singleton or concrete carry endpoint law says nothing universal about all
ranges or addition. Layout/zero-length laws are useful, but they do not prove
a hash, DRBG, sampler probability law, security property or foreign ABI.

For random sampling, separate an ideal source's probability space, exact grid
and rounding effects, algorithmic error/failure bounds, and refinement to each
compiled implementation. Statistical tests are finite evidence. Agreement
between two implementations can preserve a shared bug. The pinned kernel's
consistency/termination claims are not a theorem about every client program's
intended specification.
