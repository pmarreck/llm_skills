/- Hand-written append/reverse with structural induction, then the same facts
   from core lemmas, and how to discover them (#check, exact?, simp?). -/
namespace Lists

def app : List α → List α → List α
  | [], ys => ys
  | x :: xs, ys => x :: app xs ys

def rev : List α → List α
  | [] => []
  | x :: xs => app (rev xs) [x]

theorem length_app (xs ys : List α) : (app xs ys).length = xs.length + ys.length := by
  induction xs with
  | nil => simp [app]
  | cons x xs ih => simp [app, ih]; omega

theorem app_nil (xs : List α) : app xs [] = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [app, ih]

theorem app_assoc (xs ys zs : List α) : app (app xs ys) zs = app xs (app ys zs) := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [app, ih]

theorem rev_app (xs ys : List α) : rev (app xs ys) = app (rev ys) (rev xs) := by
  induction xs with
  | nil => simp [app, rev, app_nil]
  | cons x xs ih => simp [app, rev, ih, app_assoc]

theorem rev_rev (xs : List α) : rev (rev xs) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [rev, rev_app, ih, app]

-- Same facts via core: the hand-written functions agree with List's ++ and reverse.
theorem app_eq_append (xs ys : List α) : app xs ys = xs ++ ys := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [app, ih]

example (xs ys : List α) : (xs ++ ys).length = xs.length + ys.length := List.length_append
example (xs : List α) : xs.reverse.reverse = xs := by simp
-- Find names instead of guessing them. On this goal `exact?` printed
-- `Try this: exact List.reverse_append` and `simp?` printed
-- `Try this: simp only [List.reverse_append]`. Commit what they print, not the
-- search call, and confirm each name with `#check`.
example (xs ys : List α) : (xs ++ ys).reverse = ys.reverse ++ xs.reverse := List.reverse_append
example (xs ys : List α) : (xs ++ ys).reverse = ys.reverse ++ xs.reverse := by
  simp only [List.reverse_append]
#check @List.length_append
#check @List.reverse_reverse
#check @List.reverse_append

theorem rev_eq_reverse (xs : List α) : rev xs = xs.reverse := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [rev, ih, app_eq_append]

end Lists
#print axioms Lists.length_app
#print axioms Lists.rev_rev
#print axioms Lists.rev_eq_reverse
