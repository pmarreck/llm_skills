---
name: writing-elm
description: Write, test, review or debug Elm code, elm.json projects and Elm builds. Covers the Elm compiler from nixpkgs, offline Nix builds with elm-test-rs and elm-review, domain modeling, The Elm Architecture at scale, JSON decoder traps, JavaScript interop, rendering performance and the compile errors agents commonly hit. Use for Elm source, elm.json, elm-test/elm-review setup or Elm packaging; not merely for serving an already-built Elm bundle.
---

# Writing Elm

Researched on **2026-11-27**. The example project under `examples/` builds
with `--optimize`, passes `elm-format`, its tests and `elm-review`, all offline
in the Nix sandbox with Elm **0.19.2** from nixpkgs, and this repository's CI
reruns all of it on every commit. Claims marked *researched* come from
official docs and package metadata but were not exercised here.

## Establish the toolchain first

Read `elm.json` (`"elm-version"` and dependencies) and the project's Nix pin
before changing anything. `elm --version` must equal `elm.json`'s
`elm-version`, and the test runner must use the same compiler.

- **Use the Elm in the project's nixpkgs pin**, with nixpkgs' `elm-format`,
  `elm-test-rs` and `elm-review`. As of 2026-11-27 that is **0.19.2**. Do not
  install the compiler from npm or a release download.
- Elm 0.19.2 brought faster builds and **no language changes**, so 0.19.1
  code, tutorials and packages still apply. Upgrading means changing
  `elm-version`, the compiler and the test runner together, by advancing the
  nixpkgs pin.
- Builds and checks run inside Nix with no network. Copy the example's
  `default.nix`, `checks.nix` and `nix/` directory, and read
  [toolchain and Nix](references/toolchain-and-nix.md) before setting up or
  changing an Elm build, test runner, minifier or elm-review.

## Verification loop

1. `elm make src/Main.elm --output=/dev/null` while editing.
2. `elm make src/Main.elm --optimize` for release. It refuses to generate
   output if any `Debug.log`, `Debug.todo` or `Debug.toString` remains. Judge
   by the exit status and the output file: Elm prints "Success! Compiled N
   modules." before the DEBUG REMNANTS failure.
3. `elm-format --validate src tests review/src`. Never hand-align code;
   elm-format has no options by design.
4. `elm-test-rs --offline --compiler "$(command -v elm)"` and
   `elm-review --offline --compiler "$(command -v elm)"`.
5. `nix flake check`, with `default.nix` exposed as the package and as a
   check, and `checks.nix` as a check. [checks.nix](examples/checks.nix) runs
   steps 3 and 4 in the sandbox; `./test` runs the flake checks.

A successful compile proves types, not behavior. Test decoders against real
payloads, including missing, `null` and wrong-typed fields. Fix elm-review
findings rather than disabling rules; on the example it caught unused
constructor arguments, missing `let` annotations and unexposed types.

## Model the domain before writing views

- Replace booleans, strings and clusters of `Maybe` fields with custom types.
  `{ loading : Bool, error : Maybe String, data : Maybe a }` allows impossible
  states; `type Remote a = Loading | Failed Http.Error | Loaded a` does not.
- Wrap identifiers and validated values in opaque types with smart
  constructors (`type CardId = CardId String`, exposing the type but not the
  constructor). Parse untrusted input once at the boundary into precise types.
- Keep structured errors such as `Http.Error` in the model and render them in
  `view`, rather than flattening them to strings in `update`.
- For grouping by a constructor that carries data, add a payload-free kind
  type (`StatusKind`) instead of placeholder values such as `Blocked ""`.
- Derive an "every value" list from an exhaustive `case` (see `allKinds` in
  [Card.elm](examples/src/Card.elm)) so a new constructor cannot be silently
  left out of menus or columns.
- Annotate every top-level definition and every `let` binding. Shadowing is a
  compile error: a parameter named like any top-level value (`status`,
  `title`, `model`) fails.
- A message carries only data its handler uses: `Time.every 1000 (\_ -> Tick)`
  rather than `Tick Time.Posix` with the time ignored.

Read [architecture](references/architecture.md) for scaling an app, effects,
interop, rendering performance and testing.

## JSON decoding: the trap that compiles

`Json.Decode.maybe` and `oneOf [ field ..., succeed default ]` treat a field
that is **present but malformed** exactly like a missing one. A wrong-typed
`assignee` becomes `Nothing`, and one malformed nested item silently empties
a whole `subtasks` list. An unaided agent wrote both patterns in testing and
then described its own code as failing on bad input, which it does not. Fall
back only when the field is absent:

```elm
optional : String -> Decoder a -> Decoder (Maybe a)
optional name valueDecoder =
    Decode.oneOf
        [ Decode.field name Decode.value |> Decode.map (\_ -> True)
        , Decode.succeed False
        ]
        |> Decode.andThen
            (\present ->
                if present then
                    Decode.map Just (Decode.field name valueDecoder)

                else
                    Decode.succeed Nothing
            )
```

[DecodeField.elm](examples/src/DecodeField.elm) adds the `null`-tolerant form,
and [Tests.elm](examples/tests/Tests.elm) proves both the trap and the fix.
Recursive decoders need `Decode.lazy`; tagged unions decode with `andThen` on
the tag; report failures with `Decode.errorToString`. Read
[JSON](references/json.md) before writing or reviewing decoders or encoders.

## Architecture in brief

- Choose the lightest program: `Browser.element` to embed in a page,
  `Browser.document` to own the body, `Browser.application` for URL routing.
- Do not build nested "components" with their own `Model`/`Msg`/`update` by
  default. Use view functions that take data and message constructors; give a
  page or a genuinely stateful widget its own module when it earns it.
- Organize modules around a central type. Split along types when a file
  passes about 500 lines (the fleet's limit) rather than into
  Model/Update/View files.
- `subscriptions` is a pure function of the model: return `Sub.none` to stop.
  `Cmd.batch` runs commands in no guaranteed order.
- Decode flags from `Json.Decode.Value`. Prefer one tagged port pair over a
  port per JavaScript function. Ports are asynchronous, carry only
  JSON-compatible values, and are not allowed in published packages.

## Compile errors agents commonly hit

| Mistake | Fix |
|---|---|
| `{ model.sub \| x = 1 }` (PROBLEM IN RECORD) | bind `model.sub` in a `let`, then update it |
| a module named `Task`, `List`, `Dict`, ... (AMBIGUOUS IMPORT) | a domain name (`Card`) |
| importing an indirect dependency (MODULE NOT FOUND) | `elm install` it to make it direct |
| a parameter named like a top-level value (SHADOWING) | a distinct name (`cardStatus`) |
| a tuple of four or more | a record |
| `/` on `Int`, or `//` on `Float` | `//` for `Int`, `toFloat n / 2` for `Float` |

Read [mistakes](references/mistakes.md) for the full catalog with causes and
fixes: numeric types, `comparable` keys, recursion depth, DOM pitfalls,
interop and tooling.

## Dependencies

Add packages with `elm install author/package`, including packages that are
already indirect dependencies but are now imported directly. Set up tests
with `elm-test-rs init`: in an application, `elm install elm-explorations/test`
wrongly lands in production `dependencies`. Review the `elm.json` diff instead
of piping `yes` into prompts, never hand-edit application dependency
versions, and keep `elm-stuff/` out of version control. Regenerate
`elm-srcs.nix` with `elm2nix convert` whenever an `elm.json` changes, in the
application and in `review/`; evaluation fails until you do.

## Worked example

[examples/](examples/) is a small `Browser.element` board: decoded flags,
an opaque `CardId`, a `Remote` loading type, strict optional-field decoders, a
recursive decoder, an exhaustive kind list, a keyed list, a conditional
subscription and one tagged port. [default.nix](examples/default.nix) builds
it offline with nixpkgs' Elm and the official minifier settings,
[checks.nix](examples/checks.nix) runs elm-format, the
[tests](examples/tests/Tests.elm) and elm-review with the
[standard rule set](examples/review/src/ReviewConfig.elm), and
[nix/elm-home.nix](examples/nix/elm-home.nix) supplies the packages offline.
