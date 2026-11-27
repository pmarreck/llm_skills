# WAT, WAST and testing Wasm

Hand-written WebAssembly text (WAT) is a stack machine with no type
inference to catch operand mistakes, so its tests carry more weight than in a
high-level language. These rules come from this fleet's WAT applications
unless marked otherwise.

## Operand order

Every instruction pops its operands in the order they were pushed: the
left-hand operand goes on the stack first. For noncommutative instructions
(`sub`, `div_s`, `div_u`, `rem_*`, `shl`, `shr_*`, comparisons such as
`lt_s`), pushing in the wrong order compiles, validates and runs, and
computes the wrong value.

```wat
;; -value: push zero first, then the value.
i64.const 0
local.get $value
i64.sub

;; Wrong: computes value - 0 and keeps the sign.
local.get $value
i64.const 0
i64.sub
```

The folded form makes the order explicit: `(i64.sub (i64.const 0) (local.get
$value))`. Prefer it for noncommutative arithmetic in hand-written code.

Integer instructions also carry their signedness (`div_s` versus `div_u`,
`lt_s` versus `lt_u`, `shr_s` versus `shr_u`, `extend_i32_s` versus
`extend_i32_u`). Wasm integers have no sign of their own; the instruction
decides. Integer division by zero and signed `INT_MIN / -1` trap.

## Test behavior with WAST

WebAssembly Script (`.wast`) is the specification's own test format:
`module`, `register`, `invoke`, `assert_return`, `assert_trap`,
`assert_invalid` and `assert_malformed`. Wasmtime runs it with
`wasmtime wast FILE.wast`. Use it as the behavior-test layer for a directly
authored WAT application:

- Load the unchanged production module; do not add test-only exports to it.
- Register a deterministic host module under the import names the
  application expects, so the test controls every input.
- Write probe modules that import the application's exports and memory and
  assert on results.

WAST cannot inspect source text. A structural rule, such as "no float opcodes
outside the marked adapter", needs a separate source lint, not a behavioral
assertion that only looks like one.

## Fake hosts must check what they receive

A stand-in host that only counts calls accepts arguments in the wrong
positions. One fleet application passed its WAST suite while sending a
frequency where the real host expected a filter enum; the real host rejected
it. Give test doubles cheap domain checks (enum ranges, durations, gains),
and make the authoritative CI gate run the unchanged production module
against the real host binary from a locked input.

## Fixed point instead of floats

Floats are allowed in Wasm, but NaN bit patterns and relaxed-SIMD results may
differ between engines (*researched*). Applications that must be
deterministic, such as replayable games and simulations, keep state in
integers or fixed point and confine float use to a clearly marked adapter at
the host boundary, enforced by the source lint above.

## Validate and inspect

- `wasm-tools validate`, `wasm-tools print` (binary to text) and
  `wasm-tools parse` (text to binary). `wasm-tools` is the Bytecode Alliance's
  maintained tool and understands current proposals.
- `wasmtime wast` both validates and executes `.wast` files.
- Inspect a module's imports and exports before wiring a host: a
  mismatched import name or signature fails at instantiation, not at
  compile time.
