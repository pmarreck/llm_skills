---
name: writing-lean
description: Write, test, prove, review or debug Lean 4 programs, proofs and Lake packages. Covers pinning the toolchain, a proof workflow for agents without an editor, Lean traps and recent breaking changes, axiom and trust audits, offline Nix builds including Mathlib, and proving code written in other languages (Aeneas for Rust, Lean specifications with differential testing). Use for Lean source, lakefile or lean-toolchain changes, theorem proving, refinement proofs or Lean version migrations; not merely for running an existing Lean executable.
---

# Writing Lean

Researched on **2026-11-27**, when nixpkgs shipped Lean **4.35.0** and the
latest upstream release was 4.36.0. Every file in [examples/](examples/)
compiles with nixpkgs' Lean and passes an axiom audit in this repository's CI.
Claims marked *researched* in the references come from documentation and were
not run.

Review after: **2027-02-27**. Lean releases monthly, so past that date read
the release notes since 4.35, re-check the version-specific claims in the
references, then update this date and the research date.

Use Lean as both a programming language and a proof checker, without
conflating successful execution, cross-implementation agreement and a
kernel-checked theorem.

## Pin the language before writing code

Lean releases monthly and does not keep compatibility between releases.
Lemma names, tactic behavior and library APIs changed many times between 4.22
and 4.35. Read the project's `lean-toolchain`, Nix input or package derivation
first, and run `lean --version` and `lake --version` through that environment.
Do not search the Nix store or silently use an ambient Elan toolchain.

For this fleet, require the project's Nix derivation. If none exists, add one
and pin an exact Lean version before adopting syntax or APIs. When memory and
the compiler disagree, the compiler wins: read the
[reference manual](https://lean-lang.org/doc/reference/latest/) and the
[release notes](https://lean-lang.org/doc/reference/latest/releases/) for
every version between what you remember and the pin. Read
[traps and changes](references/traps-and-changes.md) before writing proofs.

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
theorem connects them. Make constructors of invariant-carrying types private
and export checked factories, so theorem preconditions are enforced by types
rather than by documentation.

## Prove with the goal in view

An agent without an editor cannot see goal states, and guessing tactics
against an unseen goal wastes most attempts. Work like this:

1. State the theorem with `:= by sorry` and compile. A statement that does not
   elaborate is the first bug.
2. Inspect the goal: through [lean-lsp-mcp](https://github.com/oOo0oOo/lean-lsp-mcp)
   if it is configured, through the JSON REPL, or with `lean --json` and a
   `trace_state` or failing `done` at the point of interest. See
   [tooling](references/tooling-and-nix.md#see-the-goal-before-choosing-a-tactic).
3. Never invent a lemma name. Invented names are the most common failure in
   published evaluations of LLM-written Lean. `#check` a name before using it,
   and let `exact?`, `simp?` and `rw?` find candidates. Commit the term they
   print, not the search call.
4. Try the automation first: `omega` for linear `Nat`/`Int` arithmetic, `simp`
   for rewriting, `grind` for mixed reasoning, `decide` for small finite
   facts. Structure the proof by `induction` on the data, or by functional
   induction (`fun_induction f x`) when the recursion is not structural.
5. A `simp` that closes a goal is fine. A `simp` followed by more tactics should
   be the `simp only [...]` that `simp?` prints, because the default simp set
   changes between releases.
6. Remove every `sorry`, run `#print axioms` on the headline theorems, and
   mutation-check one: break the implementation and watch the proof fail.

[Examples](#worked-examples) show each step on lists, arrays, sorting,
termination and imperative loops.

## Traps that compile

These elaborate and run, then mislead. The full table, with fixes, is in
[traps and changes](references/traps-and-changes.md).

- `Nat` subtraction truncates (`3 - 5 = 0`); `n / 0 = 0`; `UInt8` and other
  fixed-width types wrap around.
- `a[i]!` panics at runtime and yields `default` in proofs. Use `a[i]` with a
  bound proof, or `a[i]?`.
- `partial`, `unsafe`, `@[implemented_by]` and `@[extern]` make the running
  code differ from, or be invisible to, what you prove.
- Well-founded recursive definitions do not unfold by `rfl` or `decide`; use
  their equation lemmas (`simp [f]`) or functional induction.
- `Float` has no useful proof theory.
- Tabs are a hard error: indent Lean with spaces even in tab-indented repos.
- `main (args : List String)` cannot receive invalid UTF-8 unchanged; take raw
  argument bytes through a thin native launcher when they matter.

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
  are deliberately accepted and reported. Since 4.29, each `native_decide`
  adds an axiom named like `t._native.native_decide.ax_1_1`, so `#print
  axioms` shows it;
- run `#print axioms TheoremName` for headline theorems and record every
  remaining axiom rather than assuming none. `propext`, `Classical.choice` and
  `Quot.sound` are Lean's standard axioms; report them accurately instead of
  calling any nonempty list a failure. `sorryAx` means the proof is
  incomplete;
- compile or elaborate the proof modules with `--trust=0` when practical;
- for headline results, replay the build with `lean4checker --fresh` or check
  it with `lake comparator` (Lean 4.35);
- mutation-check at least one important theorem or external gate by breaking
  the implementation and observing failure before restoring it.

No checker confirms that a theorem says what you meant. Review the statement
and every definition it depends on.

## Machine integers need a model

`UInt32`, `UInt64`, `USize`, arrays, and byte buffers are efficient executable
types, but modular arithmetic and bounds can make direct proofs awkward. Choose
one of these deliberately:

- implement in `BitVec n` (with `bv_decide` for bit-level goals) or a bounded
  subtype and execute it;
- implement in machine integers and prove correspondence to a `Nat`/`Int`
  model under explicit bounds;
- retain a slower proved reference implementation and compare an optimized
  implementation through an external differential gate.

Do not claim overflow safety from test coverage alone. Conversely, do not make
the runtime unusably slow solely to maximize the amount proved; measure the
tradeoff and preserve both paths when that is useful. Compiled Lean can be an
order of magnitude or more slower than tuned Zig or Rust for byte-heavy work,
so measure before choosing it for a hot path.

## Build and verification floor

Use `nix build` as the canonical build path, with Lake invoked inside the
derivation. Follow `cross-platform-project-build-arch`; do not maintain an
optional non-Nix backend. The commands below describe the inner build/check
steps, not a second contributor build recipe. A proof-oriented package should
normally gate:

```text
lake build
lake test
lean --trust=0 <headline proof module>
source scan for sorry/admit/project axioms
#print axioms for headline theorems
external differential and mutation controls
```

Lake cannot fetch dependencies in the sandbox, and Mathlib's
`lake exe cache get` needs network. Read
[tooling and Nix](references/tooling-and-nix.md#nix-builds) for
`buildLakePackage`, lean4-nix and the fleet's fixed-output Mathlib pattern.
Use `lake shake` only as a dependency diagnostic, not as proof. Run the shipped
executable as an installed-package smoke test so an elaborated but unshipped
target cannot create a false green.

## Code written in other languages

A proof about code in another language needs one of three bridges, each with a
different guarantee: translate the code into Lean (Aeneas, for safe Rust),
specify in Lean and differentially test the implementation (the AWS Cedar
pattern), or implement in Lean and compile it. No mature translator exists for
C++, Go, Python or WebAssembly. An LLM's rewrite of code into Lean proves
things about the rewrite, not the original. Read
[cross-language](references/cross-language.md) before promising a proof about
non-Lean code.

## Worked examples

Each file in [examples/](examples/) compiles without warnings, and
[checks.nix](examples/checks.nix) fails CI if any proof uses `sorry` or an
axiom beyond the standard three.

- [Lists.lean](examples/Lists.lean): structural induction on hand-written
  `append` and `reverse`, then the same facts from core lemmas found with
  `#check`, `simp?` and `exact?`.
- [Termination.lean](examples/Termination.lean): non-structural recursion with
  `termination_by` and `decreasing_by`, proved with functional induction.
- [InsertionSort.lean](examples/InsertionSort.lean): the result is sorted
  (`List.Pairwise`) and a permutation (`List.Perm`) of the input.
- [Arrays.lean](examples/Arrays.lean): indexing with proofs, `a[i]?`, and
  relating an `Array` fold to its `List` version.
- [Imperative.lean](examples/Imperative.lean): an `Id.run do` loop with
  `let mut`, proved equal to a pure specification twice: with a `Std.Do` loop
  invariant through `mvcgen`, and with `simp` and an induction lemma.
- [Arithmetic.lean](examples/Arithmetic.lean): the `Nat` and `UInt8` traps,
  `omega`, `grind` and `decide`.

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
