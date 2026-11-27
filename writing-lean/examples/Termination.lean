/- Non-structural recursion: termination_by / decreasing_by, and functional
   induction (fun_induction) to prove a correctness property.
   Example 1: Euclid gcd.  Example 2: binary search over a sorted Array. -/
namespace Termination

-- Lean cannot prove `a % b < b` automatically, so `decreasing_by` supplies it.
-- The hypothesis is used only there, which the unused-variables linter does
-- not see: name it `_h` and refer to it as the anonymous assumption `‹_›`.
def mygcd (a b : Nat) : Nat :=
  if _h : b = 0 then a else mygcd b (a % b)
termination_by b
decreasing_by exact Nat.mod_lt _ (Nat.pos_of_ne_zero ‹_›)

theorem mygcd_dvd_left (a b : Nat) : mygcd a b ∣ a ∧ mygcd a b ∣ b := by
  fun_induction mygcd a b with
  | case1 a => simp
  | case2 a b h ih =>
    obtain ⟨h1, h2⟩ := ih
    exact ⟨(Nat.dvd_mod_iff h1).mp h2, h1⟩


-- Binary search over a sorted Array: index of the target if present.
def bsearch (a : Array Nat) (t : Nat) (lo hi : Nat) : Option Nat :=
  if h : lo < hi then
    let mid := (lo + hi) / 2
    if hm : mid < a.size then
      if a[mid] = t then some mid
      else if a[mid] < t then bsearch a t (mid + 1) hi
      else bsearch a t lo mid
    else none
  else none
termination_by hi - lo
decreasing_by all_goals omega

-- Soundness: any index returned really holds the target.
theorem bsearch_sound (a : Array Nat) (t lo hi i : Nat) :
    bsearch a t lo hi = some i → ∃ h : i < a.size, a[i] = t := by
  fun_induction bsearch a t lo hi with
  | case1 lo hi h mid hm heq =>
    intro hs; simp at hs; subst hs; exact ⟨hm, heq⟩
  | case2 lo hi h mid hm hne hlt ih => exact ih
  | case3 lo hi h mid hm hne hge ih => exact ih
  | case4 lo hi h mid hm => intro hs; simp at hs
  | case5 lo hi h => intro hs; simp at hs

end Termination
#print axioms Termination.mygcd_dvd_left
#print axioms Termination.bsearch_sound
