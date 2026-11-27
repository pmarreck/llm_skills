# Common Elm mistakes and their fixes

Each entry names the mistake, why it fails, and the fix. Entries marked
**[verified]** were reproduced with the compiler while writing this skill;
the rest come from official upgrade notes, package documentation and
community guidance.

## Elm 0.18 leftovers and other-language habits

See the table in the main skill for the common syntax replacements. More:

- **`Http.Error` shape.** 0.19 has `BadUrl String | Timeout | NetworkError |
  BadStatus Int | BadBody String`; there is no response record. Handle every
  case explicitly ([Main.elm](../examples/src/Main.elm) shows one).
- **Old decode pipeline package.** `NoRedInk/elm-decode-pipeline` became
  `NoRedInk/elm-json-decode-pipeline`; its `decode` became
  `Json.Decode.succeed`.
- **`String.toInt` returning `Result`.** It returns `Maybe Int` in 0.19.
- **Shadowing [verified].** Rebinding any name already in scope, including a
  top-level function name used as a parameter (`kind status` when `status` is
  also a function), is a SHADOWING error. Choose distinct names
  (`cardStatus`, `newModel`, `acc`).
- **Module named after a package module [verified in baseline testing].** A
  local module with the same name as one from elm/core (`Task`, `List`,
  `Maybe`, `Dict`, `Set`, `Array`, `String`, `Char`, `Tuple`, `Process`) or
  another installed package (`Time`, `Http`, `Url`) causes AMBIGUOUS IMPORT.
  Use a domain name.
- **Unlisted direct dependency [verified in baseline testing].** Importing a
  module from a package that is only an indirect dependency fails with MODULE
  NOT FOUND. `elm install` it, which promotes it to direct.
- **Test packages in production dependencies [seen in skill trial].** In an
  application, `elm install elm-explorations/test` adds the package to
  `dependencies`, not `test-dependencies`. Set up tests with the runner's
  init command instead: `elm-test-rs init` **[verified]** places
  `elm-explorations/test` under `test-dependencies` (`elm-test init` does the
  same for the npm runner).
- **Percent-encoded route segments [verified].** `Url.Parser.string`
  does not decode `%20` and friends; use
  `Url.Parser.custom "ID" Url.percentDecode` and test route round trips.

## Numbers, comparison and data structures

- **`/` versus `//`.** `/` is Float-only and `//` is Int-only, with no implicit
  conversion: `toFloat count / 2` or `count // 2`. Literals are `number` until
  context decides, so annotate top-level numeric values.
- **`modBy` argument order.** `modBy 3 n` is n mod 3; `remainderBy` differs for
  negative numbers.
- **`comparable` keys.** `Dict` and `Set` keys must be `Int`, `Float`, `Char`,
  `String`, or tuples and lists of those. A custom type is not comparable.
  Convert to a key (`colorKey : Color -> Int`), use an association list for
  small collections, or use a package such as `turboMaCk/any-dict`.
- **Tuples stop at three [verified by research compile].** Use a record.
- **Nested record update [verified].** `{ model.sub | x = 1 }` is a parse
  error (PROBLEM IN RECORD). Bind first:
  `let sub = model.sub in { model | sub = { sub | x = 1 } }`, or write a small
  `mapSub : (Sub -> Sub) -> Model -> Model` helper.
- **Import cycles.** Mutually importing modules are rejected. Move the shared
  types into a third module.
- **Stack depth.** Only direct self-recursion in tail position becomes a
  loop. Recursing on the result (`x + sum rest`) over a large list can
  overflow; carry an accumulator or use `List.foldl`. Mutual recursion is not
  optimized.
- **Quadratic lists.** `acc ++ [ x ]` in a loop is O(n²). Cons onto the front
  and reverse once, and use `Array` for indexed access. `List.length` is O(n).
- **Strings.** `String` is a JavaScript string. Prefer `String.slice`,
  `String.indexes` and `String.join` over round trips through
  `String.toList`.

## Maybe, Bool and stringly typed code

- **`Maybe.withDefault` hiding bugs.** `Dict.get id cards |> Maybe.withDefault
  emptyCard` turns a missing record into a plausible fake one. Handle
  `Nothing` with `case`, or keep the `Maybe` flowing with `Maybe.map` and
  `Maybe.andThen`. A default belongs only where the domain defines one.
- **Bool and Maybe clusters.** `{ loading : Bool, error : Maybe String,
  data : Maybe a }` permits contradictions. Use one custom type.
- **String ids.** Wrap them in opaque types so different kinds of id cannot be
  swapped.
- **Placeholder payloads [seen in baseline testing].** Grouping by status with
  `Blocked ""` stand-ins. Add a payload-free kind type and an exhaustive list
  of kinds ([Card.elm](../examples/src/Card.elm)).

## Architecture

- **Components everywhere.** Copying React-style components into nested TEA
  modules multiplies `Msg` wrapping. Start with view functions.
- **Assuming `Cmd.batch` order.** It has none.
- **Timers that never stop.** A subscription lasts as long as
  `subscriptions` returns it; gate it on model state.
- **Chained `Process.sleep` as an interval.** Drifts and cannot be canceled.
  Use `Time.every`.
- **Hard-coded `Time.utc` for display.** Fetch the zone with `Time.here`.
- **Reused seeds.** Store and advance the `Seed`.

## JSON

The absent-versus-malformed trap, recursion, tagged unions and error
reporting are covered in [JSON](json.md). The short version:
`Decode.maybe` and `oneOf [ ..., succeed default ]` silently swallow
malformed data **[verified]**; recursive decoders need `Decode.lazy`; report
errors with `Decode.errorToString`.

## DOM and interop

- Transforming the value bound to an input moves the caret.
- `attribute "value"` sets only the initial value; use `value`.
- An `<a>` without `href`, or a full page load inside `Browser.application`.
- `onClick` where `preventDefaultOn` or `custom` is needed.
- `lazy` arguments rebuilt every render.
- Reorderable lists without `Html.Keyed`.
- Trusting flags instead of decoding them.
- Expecting a synchronous return value from a port.
- Ports or kernel code in a package meant for publication.
- Embedding `Browser.document` or `Browser.application` beside other content;
  use `Browser.element`.

## Tooling and process

- Skipping `elm-format --validate` and `elm-review` in `./test`.
- Leaving `Debug` calls until release, then discovering `--optimize` refuses
  them. Run `NoDebug` rules continuously.
- Trusting "Success!" text from `elm make --optimize` instead of its exit
  status **[verified with 0.19.3]**.
- Missing top-level type annotations, which push errors far from their cause.
- Mismatched compiler, `elm.json` `elm-version` and test runner versions.
- Committing `elm-stuff/`.
- Piping `yes` into `elm install` and committing whatever it changed.
- Stale `elm-srcs.nix` or `registry.dat` after `elm.json` changes, or an
  elm2nix `registry.dat` with Elm 0.19.3 **[verified]**.
