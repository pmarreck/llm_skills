---
name: lean4-development
description: Build, port, prove, test, or review Lean 4 libraries and executables while pinning the actual Lean toolchain and keeping proof claims honest. Use for Lean 4 code, Lake packages, theorem-proving experiments, executable refinement proofs, or migrations from older Lean versions.
---

# Lean 4 development

Use Lean as both a programming language and a proof checker without conflating
successful execution, cross-implementation agreement, and a kernel-checked
theorem.

## Pin the language before writing code

Lean intentionally has limited compatibility between monthly releases. Read the
project's `lean-toolchain`, Nix input, or package derivation first and run
`lean --version` plus `lake --version` through that environment. Do not search
the Nix store or silently use an ambient Elan toolchain.

For this fleet, prefer the project's Nix derivation. If none exists, add one and
pin an exact Lean version before adopting syntax or APIs. Check the matching
[Lean reference](https://lean-lang.org/doc/reference/latest/) and the pinned
release's source/API when memory and the compiler disagree.

## Separate four artifacts

Keep these boundaries explicit:

1. A mathematical specification using `Nat`, `Int`, finite types, or predicates
   chosen for tractable reasoning.
2. A pure executable implementation with no CLI, environment, filesystem, or
   entropy I/O.
3. Refinement theorems connecting executable results to the specification.
4. A thin executable adapter that owns parsing, formatting, entropy, and other
   effects.

An executable implementation is not automatically a specification. A theorem
about a second model is not evidence about production code until a refinement
theorem connects them.

## Work red to green

Before implementation, add at least one failing executable control derived from
the external contract and one theorem statement that cannot yet elaborate or
close. Then:

- use external official vectors or an independent implementation for exact
  differential checks;
- use Lean theorems for invariants and refinement properties;
- use exhaustive finite checks, metamorphic properties, or mutation controls
  where no external oracle exists;
- keep cross-language tests outside Lean so Lean cannot redefine its own oracle.

Prefer small proved components composed into a larger result. State exactly
which boundary remains empirical.

## Keep the trusted proof path small

For claims intended to be kernel-checked:

- do not use `sorry`, `admit`, new `axiom` declarations, or `unsafe` definitions
  in their dependency path;
- prefer ordinary proof terms, `simp`, `omega`, `grind`, and decidable finite
  reasoning that produces kernel-checkable terms;
- treat `native_decide`, compiler execution, FFI results, benchmarks, and
  generated expected values as tests unless their additional trust assumptions
  are deliberately accepted and reported;
- run `#print axioms TheoremName` for headline theorems and record every
  remaining axiom rather than assuming none;
- compile or elaborate the proof modules with trust level zero when practical;
- mutation-check at least one important theorem or external gate by breaking the
  implementation and observing failure before restoring it.

`Classical.choice`, quotient soundness, and propositional extensionality are
standard Lean axioms with different implications from a project-specific
assumption. Report them accurately instead of calling any nonempty axiom list a
failure.

## Machine integers need a model

`UInt32`, `UInt64`, `USize`, arrays, and byte buffers are efficient executable
types, but modular arithmetic and bounds can make direct proofs awkward. Choose
one of these deliberately:

- implement in `BitVec n` or a bounded subtype and extract/execute it;
- implement in machine integers and prove correspondence to a `Nat`/`Int`
  model under explicit bounds;
- retain a slower proved reference implementation and compare an optimized
  implementation through an external differential gate.

Do not claim overflow safety from test coverage alone. Conversely, do not make
the runtime unusably slow solely to maximize the amount proved; measure the
tradeoff and preserve both paths when that is useful.

## Build and verification floor

Use Lake through the pinned environment and make the canonical project runner
invoke it. A serious proof-oriented package should normally gate:

```text
lake build
lake test
lean -t 0 <headline proof module>
source scan for sorry/admit/project axioms
#print axioms for headline theorems
external differential and mutation controls
```

Use `lake shake` only as a dependency diagnostic, not as proof. Run the shipped
executable as an installed-package smoke test so an elaborated but unshipped
target cannot create a false green.

## Report the scope of correctness

End proof-oriented work with a short claim matrix:

- theorem proved and its exact statement;
- executable code covered by a refinement theorem;
- behavior checked only by external vectors or differential tests;
- security, probability, numerical-error, parser, I/O, and compiler properties
  not proved;
- axioms and trusted components;
- build and runtime cost relative to an ordinary implementation;
- recommendation: production implementation, proved reference oracle, selective
  proof layer, or no Lean adoption.

Never describe cryptographic security, distribution quality, constant-time
behavior, absence of compiler bugs, or OS entropy quality as proved merely
because the surrounding Lean functions type-check.
