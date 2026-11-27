# Lean traps and recent changes

Checked 2026-11-27. Items marked *verified* were compiled with Lean 4.35.0
from nixpkgs (most also appear in [examples/](../examples/)). The version
history comes from the
[release notes](https://lean-lang.org/doc/reference/latest/releases/); read
the notes for every release between the version you remember and the
project's pinned version before trusting memory.

## Semantics that compile and then surprise

| Trap | What happens | What to do |
|---|---|---|
| `Nat` subtraction | `3 - 5 = 0` (*verified*) | Use `Int`, or carry the hypothesis `b ≤ a`; `omega` handles truncated subtraction |
| Division and modulo by zero | `n / 0 = 0` and `n % 0 = n` (*verified*) | State the nonzero divisor as a hypothesis in specifications |
| Fixed-width integers | `UInt8`, `UInt64` and the like wrap around (*verified*) | Model them with `BitVec n` or prove bounds against a `Nat` model |
| `a[i]!` | Panics at runtime and returns `default` in proofs, which hides bugs | Use `a[i]` with a bound proof, or `a[i]?` and handle `none` |
| `Float` | IEEE semantics with no useful proof theory | Keep proved code in `Nat`, `Int`, `Rat`-like or fixed-point types |
| `partial def` | Runs, but its body is opaque to proofs | Prove termination (`termination_by`, `decreasing_by`) or use fuel |
| `unsafe`, `@[implemented_by]`, `@[extern]` | The code that runs is not the code you proved | Treat the replacement as trusted; cover it with differential tests |
| Well-founded recursion | Definitions are irreducible by default, so `rfl` and `decide` do not unfold them | Use the generated equation lemmas (`simp [f]`, `unfold f`) or functional induction |
| `native_decide` | Trusts the compiler; since 4.29 each use adds an axiom named like `t._native.native_decide.ax_1_1` (*verified*) | Use `decide` (kernel) for small finite facts; treat native results as tests |
| `main (args : List String)` | Cannot receive invalid UTF-8 arguments unchanged | Take raw bytes through a thin native launcher when exact argv bytes matter |
| Public constructors | Callers can build values that violate the invariants theorems assume | Make the constructor private and export checked factories, so preconditions are typed |
| Tabs | `error: tabs are not allowed` (*verified*) | Indent Lean with spaces even in tab-indented repositories |

## Proof habits that fail

- **Invented names.** Most failed LLM proofs cite a lemma that does not exist,
  or the right lemma without its namespace. `#check` every name, and use
  `exact?`, `simp?` or `rw?` to find real ones.
- **Lean 3 or Mathlib 3 syntax.** `begin ... end`, `assume`, `λ x,`,
  `cases h with a b`, `{ }` tactic blocks, and `snake_case` type names such as
  `nat`. Lean 4 uses `by`, `fun x =>`, `obtain ⟨a, b⟩ := h`, `·` focusing,
  `Nat`.
- **Unpinned `simp` in the middle of a proof.** The default simp set changes
  between releases (4.29 stopped simplifying instances by default; 4.31 closes
  `simpa using h` goals at reducible transparency). A `simp` that finishes a
  goal is fine. A `simp` followed by more tactics should be the
  `simp only [...]` that `simp?` prints, so the next steps see a stable goal.
- **Mathlib names in core-only projects.** `List.Sorted` and
  `List.insertionSort` are Mathlib definitions (*verified* unknown in core
  4.35). Core has `List.Pairwise (· ≤ ·)` and `List.Perm`; see
  [InsertionSort.lean](../examples/InsertionSort.lean).
- **Guessing `fun_induction` case binders.** In `fun_induction f x with
  | case2 a b h ih => ...`, the binders name only the variables and
  hypotheses that case introduces, and a wrong count is an error. Leave the
  case as `?_` in a scratch copy and read the goal first (*verified*).
- **`rw [h]` with a bare variable on the left.** If `h : a = e`, `rw` replaces
  every `a`, including those inside other terms such as `f a b`. Prefer the
  lemma that uses `h` directly, for example `(Nat.dvd_mod_iff h1).mp h2`.
- **Leaning on automatic termination.** Lean cannot prove `a % b < b` by
  itself, so Euclid's algorithm needs an explicit `decreasing_by`. A
  hypothesis used only there trips the unused-variables linter; name it `_h`
  and refer to it as `‹_›` (*verified*,
  [Termination.lean](../examples/Termination.lean)).
- **Expecting `decide` to scale.** It evaluates in the kernel. It is right
  for small finite facts and too slow for large ones; reformulate, or use
  `omega`, `simp` or `grind`.
- **Proving facts about a model and claiming the implementation.** A theorem
  about `specSum` says nothing about `fastSum` until a theorem connects them.

## Tactics to reach for

- `omega` closes linear arithmetic over `Nat` and `Int`, including truncated
  subtraction, division and modulo by literals.
- `simp` rewrites with the simp set; `simp [f]` unfolds `f` through its
  equation lemmas.
- `grind` (since 4.22) combines congruence closure, linear integer arithmetic
  (its solver was renamed from `cutsat` to `lia` in 4.26), algebra and case
  splitting. Try it before writing a long manual proof. Its proofs depend on
  `Classical.choice` where `omega` and `simp` proofs of the same goal do not
  (*verified*), which matters only to a project that avoids classical axioms.
- `decide` for small decidable propositions, checked by the kernel.
- `induction xs with ...`, or functional induction with
  `fun_induction f x` or `induction x using f.induct`, which follows the
  recursion of `f` and supplies the right hypotheses.
- `bv_decide` for `BitVec` goals. It uses a SAT solver, and its trusted
  checker is fixed and vetted.
- Imperative code (`Id.run do`, `let mut`, `for`): the `Std.Do` framework
  generates verification conditions from a loop invariant. It needs both
  `import Std.Do` and `import Std.Tactic.Do`. Lean 4.35 deprecates `mvcgen`
  in favor of the experimental `vcgen` (`set_option experimental.vcgen true`),
  but `vcgen` failed on the simple loop proof in
  [Imperative.lean](../examples/Imperative.lean) that `mvcgen` closes
  (*verified*). That example keeps `mvcgen` with the deprecation warning
  silenced. Expect this API to keep changing; for a loop that is just a fold,
  `simp` with an induction lemma is often simpler.
- `exact?`, `simp?` and `rw?` report their suggestion as an `info` message
  ("Try this: ..."), so a clean exit does not mean they were removed.

## Changes since Lean 4.22 that break older knowledge

Lean releases monthly: 4.22 (2025-08), 4.26 (2025-12), 4.30 (2026-05),
4.35 (2026-10). Notable breaks:

- **4.22:** the new compiler replaced the old one; `grind` arrived; `mvcgen`
  arrived (experimental); the experimental `module` system (where `private` is
  the default visibility) arrived.
- **4.26:** `String.mk`, `List.asString` and `String.data` were deprecated for
  `String.ofList` and `String.toList`; `Substring` became `Substring.Raw`;
  list "sorted" lemmas were renamed to "pairwise".
- **4.28:** `Std.Range` became `Std.Legacy.Range`, replaced by the new range
  notation; iterator APIs moved into `Std`; `lake shake` became built in.
- **4.29:** `simp` and `dsimp` stopped simplifying instances by default (use
  `simp +instances`); `isDefEq` no longer raises transparency for implicit
  arguments; `native_decide` began adding per-computation axioms.
- **4.30:** the new code generator was completed; theorems became opaque in
  almost every way, including in the kernel; `inferInstanceAs` needs exact
  types.
- **4.31:** stricter indentation inside `by` blocks; `apply` and `rewrite`
  subgoal tags changed, which can break `case h =>` scripts.
- **4.35:** `mvcgen` deprecated for `vcgen`; `Decidable` became a structure
  (`isTrue` and `isFalse` still work as patterns); stricter instance search;
  `rwa ... at h` fails unless the rewrite closes the goal; `constructor` warns
  when several constructors match; `Lean.reduceBool`, `ofReduceBool` and
  `trustCompiler` were removed.

While compiling the examples, core 4.35 also reported `Array.sum_eq_sum_toList`
as deprecated in favor of `Array.sum_toList`. Deprecation warnings like this
name the replacement; read them instead of silencing them.
