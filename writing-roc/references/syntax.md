# Current Roc syntax

Scope: new Zig-based compiler; sources reviewed 2026-10-04 at the revision in
`../SKILL.md`. Resolve API names against the project's compiler/platform.

## Frequent syntax traps

| Purpose | Current form | Older form to avoid copying blindly |
|---|---|---|
| Function value | `\|x, y\| x + y` | `\x, y -> x + y` |
| Function call | `add(2, 3)` | `add 2 3` |
| Type application | `List(Str)`, `Try(I64, ParseErr)` | `List Str`, `Result I64 ParseErr` |
| Tag payload | `Ok(3)`, `Err(BadInput)` | `Ok 3` |
| Branching | `match x { ... }`, with `Ok(v) => v` branches on separate lines | `when x is` |
| Effects | `read! : Path => Try(Str, ReadErr)` | old `Task`-based API assumptions |
| Text interpolation | `"value=${n.to_str()}"` | expecting implicit numeric-to-string conversion |
| Record update | `{ ..old, count: 2 }` | `{ old & count: 2 }` |
| Built-in naming | `I64.from_str`, `List.fold` | camelCase names, `List.walk` |

Sources: [official syntax example](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/test/echo/all_syntax_test.roc),
[tutorial](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/mini-tutorial-new-compiler.md).
The older column is a dialect warning, not a mechanical migration recipe.

## Expressions and data

```roc
add : I64, I64 -> I64
add = |a, b| a + b

label = if add(1, 2) == 3 "three" else "other"
person = { name: "Ada", count: 1 }
updated = { ..person, count: 2 }
{ name, count } = updated
pair = (name, count)
names = ["Ada", "Grace"]
length = names.len()
mapped = names.map(|s| s.trim())
joined = mapped |> Str.join_with(", ")
```

Blocks return their last expression. Bindings, loops and `return` are statements;
use a block when they are needed inside an expression. Ordinary binding
reassignment/shadowing generates diagnostics. Local mutable loops use
`var $total = 0`, then `$total = $total + n`; inclusive ranges use `1..=10`.
`#` starts a comment; `##` introduces a documentation comment.

For a function `f(a, b)`, `a |> f(b)` passes the left side first. Dot-call methods
resolve statically through the value's type; they are not dynamic object dispatch.

## Types and errors

Annotations go above definitions. Lowercase type names are variables, e.g.
`identity : a -> a`. A structural union can be `[Ready, Failed(Str)]`;
`Color := [Red, Blue]` defines a distinct nominal type. `::` makes a nominal
type opaque outside its module. `:` defines an alias, not a nominal type.
Use explicit construction for a numeric newtype, e.g. `UserId.(42)`.

```roc
first_number : List(Str) -> Try(I64, _)
first_number = |strings| {
	first = strings.first()?
	number = I64.from_str(first)?
	Ok(number)
}

message = match first_number(["7"]) {
	Ok(n) => n.to_str()
	Err(ListWasEmpty) => "empty input"
	Err(BadNumStr) => "invalid number"
}
```

`Try(a, e)` carries `Ok(a)` or `Err(e)`. Postfix `?` unwraps success or returns
the error from the enclosing function, which must return `Try`. `?? default`
supplies a fallback; it discards the error, so use it only intentionally.
Match tags with payload parentheses. Lists are homogeneous; list patterns
include `[]`, `[head, .. as tail]`. Prefer exhaustive named branches to `_`
for closed, known outcomes. No null value is needed; represent absence explicitly.

Numeric types include signed/unsigned 8–128-bit integers, `F32`, `F64` and
fixed-point `Dec`. Unconstrained numbers default to `Dec`; annotate when
integer or IEEE floating-point behavior is required. Do not treat `Dec` as
arbitrary precision or assume overflow is impossible.

Sources: [types](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/types.md),
[numbers](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/numbers.md),
[tag unions](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/tag-unions.md),
[static dispatch](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/static-dispatch.md).

## Tests

```roc
expect add(2, 3) == 5
expect first_number([]) == Err(ListWasEmpty)
expect first_number(["wrong"]) == Err(BadNumStr)
```

`roc test` discovers top-level expectations in the main module and imported
local modules, but not downloaded dependencies. Include required entrypoints
in the project's complete runner. `dbg value` is a diagnostic statement, not
an application logging API; optimization may change when diagnostics appear.

## Verification evidence

On 2026-10-04, the available Linux x86_64 compiler reported
`Roc compiler version debug-939d62d0`. Its `check --no-cache` accepted
`examples/main.roc`; `test --no-cache --verbose` passed all 16 expectations,
including the imported `Label.roc` expectation. Execution printed
`Roc quick reference` and returned success; `fmt --check examples` passed.
Checks were bounded with `--jobs=4` where supported.

Independent negative fixtures returned status 1 for a `Str` assigned to an
`I64` annotation and for a false top-level expectation. Successful output
alone was not used as the acceptance criterion.

This compiler is from the new generation but is not asserted to be the exact
official source revision cited above. The examples exercise common syntax,
not all advanced module/version features. No native Mac/Windows check or
custom LuaJIT-backend conformance is claimed. Shared skill CI checks portable
discovery; the compiler validation above was a separate local smoke run.
