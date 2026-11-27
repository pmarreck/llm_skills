/- Arithmetic traps: Nat truncating subtraction, division by zero, UInt8
   wraparound, omega for linear arithmetic, grind, and decide. -/
namespace Arithmetic

example : 3 - 5 = 0 := by decide
example : (3 : Nat) - 5 = 0 := rfl
example : (7 : Nat) / 0 = 0 := by decide
theorem div_zero' (n : Nat) : n / 0 = 0 := Nat.div_zero n
example (n : Nat) : n % 0 = n := Nat.mod_zero n
example : (255 : UInt8) + 1 = 0 := by decide
example : (0 : UInt8) - 1 = 255 := by decide
-- Truncation is why a hypothesis is needed here:
theorem sub_add_cancel' (a b : Nat) (h : b ≤ a) : a - b + b = a := by omega
-- omega handles +, *, literals, /, % by constants, and case splits on ≤ < ∧ ∨ ¬:
theorem lin (x y : Nat) (h1 : 2 * x + 3 * y = 12) (h2 : x < 4) : y ≥ 1 := by omega
theorem div_mod_lit (n : Nat) : n % 4 < 4 ∧ n / 4 * 4 + n % 4 = n := by omega
-- grind: congruence closure + linear arithmetic + case analysis
theorem g1 (a b c : Nat) (f : Nat → Nat) (h : a = b) (h2 : f b = c) : f a = c := by grind
theorem g2 (xs ys : List Nat) : (xs ++ ys).length = ys.length + xs.length := by grind
-- decide: small closed decidable props
example : ∀ x : Fin 5, x.val * x.val < 17 := by decide
example : (10 : Nat).gcd 4 = 2 := by decide

end Arithmetic
#print axioms Arithmetic.sub_add_cancel'
#print axioms Arithmetic.lin
#print axioms Arithmetic.g1
#print axioms Arithmetic.g2
