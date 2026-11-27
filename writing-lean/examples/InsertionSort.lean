/- Insertion sort on List Nat: the result is sorted (List.Pairwise (· ≤ ·);
   core 4.35 has no List.Sorted and no List.insertionSort) and a permutation
   (List.Perm, notation ~) of the input. -/
namespace InsertionSort

def insert (x : Nat) : List Nat → List Nat
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insert x ys

def isort : List Nat → List Nat
  | [] => []
  | x :: xs => insert x (isort xs)

theorem insert_perm (x : Nat) (l : List Nat) : (insert x l).Perm (x :: l) := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons y ys ih =>
    unfold insert
    split
    · exact List.Perm.refl _
    · exact ((List.Perm.cons y ih).trans (List.Perm.swap x y ys))

theorem isort_perm (l : List Nat) : (isort l).Perm l := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons x xs ih => exact (insert_perm x _).trans (List.Perm.cons x ih)

theorem mem_insert (a x : Nat) (l : List Nat) : a ∈ insert x l ↔ a = x ∨ a ∈ l := by
  rw [(insert_perm x l).mem_iff]; simp

theorem insert_sorted (x : Nat) (l : List Nat) (h : l.Pairwise (· ≤ ·)) :
    (insert x l).Pairwise (· ≤ ·) := by
  induction l with
  | nil => simp [insert]
  | cons y ys ih =>
    rw [List.pairwise_cons] at h
    obtain ⟨hy, hys⟩ := h
    unfold insert
    split
    · rename_i hxy
      rw [List.pairwise_cons]
      refine ⟨?_, List.pairwise_cons.mpr ⟨hy, hys⟩⟩
      intro a ha
      simp at ha
      rcases ha with rfl | ha
      · exact hxy
      · exact Nat.le_trans hxy (hy a ha)
    · rename_i hxy
      rw [List.pairwise_cons]
      refine ⟨?_, ih hys⟩
      intro a ha
      rw [mem_insert] at ha
      rcases ha with rfl | ha
      · omega
      · exact hy a ha

theorem isort_sorted (l : List Nat) : (isort l).Pairwise (· ≤ ·) := by
  induction l with
  | nil => simp [isort]
  | cons x xs ih => exact insert_sorted x _ ih

theorem isort_correct (l : List Nat) :
    (isort l).Pairwise (· ≤ ·) ∧ (isort l).Perm l := ⟨isort_sorted l, isort_perm l⟩

example : isort [3, 1, 2] = [1, 2, 3] := by decide

end InsertionSort
#print axioms InsertionSort.isort_correct
