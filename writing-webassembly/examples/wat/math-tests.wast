;; Assertions for math.wat. Standard WAST has no include directive, so the
;; check prepends math.wat to this file: the assertions run against the
;; production module itself, never a copy that could drift from it.

(assert_return (invoke "sub" (i32.const 10) (i32.const 3)) (i32.const 7))
(assert_return (invoke "sub" (i32.const 3) (i32.const 10)) (i32.const -7))
(assert_return (invoke "neg" (i32.const 5)) (i32.const -5))
(assert_return (invoke "neg" (i32.const 0x80000000)) (i32.const 0x80000000))
(assert_return (invoke "checked_add" (i32.const 2) (i32.const 3)) (i32.const 5))
(assert_trap (invoke "checked_add" (i32.const 0x7fffffff) (i32.const 1)) "unreachable")
(assert_trap (invoke "div" (i32.const 1) (i32.const 0)) "integer divide by zero")
(assert_trap (invoke "div" (i32.const 0x80000000) (i32.const -1)) "integer overflow")
