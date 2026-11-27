/- Imperative style (Id.run do / let mut / for) proved equal to a pure spec.
   Part A uses the Std.Do framework's `mvcgen` tactic with a loop invariant.
   Lean 4.35 deprecates `mvcgen` in favor of the experimental `vcgen`, which
   failed on this goal, so the deprecation warning is silenced below. When the
   pinned Lean changes, check whether `vcgen` handles this proof. Part B shows
   that plain `simp` and an induction lemma also work for a loop this simple. -/
import Std.Do
import Std.Tactic.Do
open Std.Do
set_option mvcgen.warning false
set_option linter.deprecated.syntax false

namespace Imperative

def sumLoop (arr : Array Nat) : Nat := Id.run do
  let mut s := 0
  for x in arr do
    s := s + x
  return s

-- A: mvcgen with an invariant over the loop cursor (prefix sum so far).
theorem sumLoop_spec (arr : Array Nat) : sumLoop arr = arr.toList.sum := by
  generalize h : sumLoop arr = r
  apply Id.of_wp_run_eq h
  mvcgen
  case inv1 => exact ⇓⟨cur, s⟩ => ⌜s = cur.prefix.sum⌝
  all_goals simp_all

-- B: unfold and let simp normalize the loop to a foldl.
theorem sumLoop_spec' (arr : Array Nat) : sumLoop arr = arr.toList.sum := by
  have key : ∀ (l : List Nat) (init : Nat), l.foldl (· + ·) init = init + l.sum := by
    intro l; induction l with
    | nil => simp
    | cons x xs ih => intro init; simp [ih]; omega
  simp [sumLoop, ← Array.foldl_toList, key]

end Imperative
#print axioms Imperative.sumLoop_spec
#print axioms Imperative.sumLoop_spec'
