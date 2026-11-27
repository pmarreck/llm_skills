/- Arrays: proof-carrying indexing, a[i]? and a[i]!, size facts, and a sum
   related to the List version via Array.toList. -/
namespace Arrays

def a : Array Nat := #[10, 20, 30]

example : a[1] = 20 := by decide
example (arr : Array Nat) (i : Nat) (h : i < arr.size) : arr[i] = arr[i]'h := rfl
-- `by get_elem_tactic` / `by omega` discharges the bound automatically when in scope:
def first (arr : Array Nat) (h : 0 < arr.size) : Nat := arr[0]
def at2 (arr : Array Nat) (h : 2 < arr.size) : Nat := arr[2] + arr[1]
example : a[5]? = none := by decide
example : a[1]? = some 20 := by decide
example : a[1]! = 20 := by decide
example (arr : Array Nat) (i : Nat) (h : i < arr.size) : arr[i]? = some arr[i] := by simp [h]
example (arr : Array Nat) (i : Nat) (h : ¬ i < arr.size) : arr[i]? = none := by simp [h]

example (arr : Array Nat) (x : Nat) : (arr.push x).size = arr.size + 1 := Array.size_push x
example (arr : Array Nat) (x : Nat) : (arr.push x).toList = arr.toList ++ [x] := by simp
example (arr : Array Nat) (x : Nat) : (arr.push x)[arr.size]? = some x := by simp

-- Explicit fold, related to the list version.
def sumA (arr : Array Nat) : Nat := arr.foldl (· + ·) 0

theorem sumA_eq_list (arr : Array Nat) : sumA arr = arr.toList.sum := by
  unfold sumA
  rw [← Array.foldl_toList]
  generalize arr.toList = l
  suffices ∀ init, l.foldl (· + ·) init = init + l.sum by simpa using this 0
  induction l with
  | nil => simp
  | cons x xs ih => intro init; simp [ih]; omega

theorem sumA_push (arr : Array Nat) (x : Nat) : sumA (arr.push x) = sumA arr + x := by
  simp [sumA_eq_list]

end Arrays
#print axioms Arrays.sumA_eq_list
#print axioms Arrays.sumA_push
