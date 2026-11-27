(module
  ;; i32.sub pops b then a and computes a - b (left operand pushed first).
  (func (export "sub") (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.sub)
  ;; Negation: 0 - x, so push 0 first, then the value, then i32.sub.
  (func (export "neg") (param $x i32) (result i32)
    i32.const 0
    local.get $x
    i32.sub)
  ;; Checked add: traps on signed overflow (unreachable), otherwise returns a+b.
  (func (export "checked_add") (param $a i32) (param $b i32) (result i32)
    (local $s i32)
    local.get $a
    local.get $b
    i32.add
    local.set $s
    ;; overflow iff a and b have the same sign and s differs: ((a^s)&(b^s)) < 0
    local.get $a local.get $s i32.xor
    local.get $b local.get $s i32.xor
    i32.and
    i32.const 0
    i32.lt_s
    if unreachable end
    local.get $s)
  (func (export "div") (param i32 i32) (result i32)
    local.get 0 local.get 1 i32.div_s))
