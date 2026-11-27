---
name: writing-elm
description: Write, test, review or debug Elm code, elm.json projects and Elm builds. Covers current compilers (0.19.2 in nixpkgs, 0.19.3 upstream), offline Nix builds, domain modeling, The Elm Architecture at scale, JSON decoder traps, JavaScript interop, rendering performance, and the outdated Elm 0.18 patterns agents still emit. Use for Elm source, elm.json, elm-test/elm-review setup or Elm packaging; not merely for serving an already-built Elm bundle.
---

# Writing Elm

Researched on **2026-11-27**. The example project under `examples/` was
compiled with `--optimize`, formatted, tested and built offline in the Nix
sandbox with Elm **0.19.2** from nixpkgs on that date, and also with the 0.19.3
release binary. Claims marked *researched* come from official docs, release
notes and package metadata but were not exercised here.

## Establish the toolchain first

Read `elm.json` (`"elm-version"` and dependencies) and the project's Nix pin
before changing anything. `elm --version` must equal `elm.json`'s
`elm-version`, and the test runner must target the same compiler.

- **Default: the newest Elm in the project's nixpkgs pin**, built by Nix with
  its matching test runner (`elmPackages.elm` and `elmPackages.elm-test` or
  `elm-test-rs`). As of 2026-11-27 that is **0.19.2**.
- Elm resumed releases after seven years: 0.19.2 (2026-07-06) brought faster
  builds and 0.19.3 (2026-10-02) internal "correct by construction" work.
  **Neither changed the language**, so 0.19.1 code, tutorials and packages
  still apply. Upgrading means changing `elm-version`, the compiler and the
  test runner together, normally by advancing the nixpkgs pin.
- Use a release newer than nixpkgs (0.19.3 today) only when the owner or the
  project explicitly requires it: [elm-release-binary.nix](examples/nix/elm-release-binary.nix)
  pins the official binary, verified on Linux only. Never mix compiler
  versions with `elm.json` or the test runner.
- A `0.19.4-beta` tag exists with no release. Do not target it. Announced
  `equatable`/`hashable` types are unreleased; do not write code assuming them.
- Builds run inside Nix with no network, using `elmPackages.fetchElmDeps` with
  elm2nix-generated sources. Read [toolchain and Nix](references/toolchain-and-nix.md)
  before setting up or changing an Elm build, test runner, minifier or
  elm-review; it records which `registry.dat` each compiler accepts.

## Verification loop

Run these through the project's Nix environment and `./test`:

1. `elm make src/Main.elm --output=/dev/null` while editing.
2. `elm make src/Main.elm --optimize` for release. It refuses to generate
   output if any `Debug.log`, `Debug.todo` or `Debug.toString` remains. Judge
   by the exit status and the output file: 0.19.3 still prints "Success!
   Compiled 1 module." before the DEBUG REMNANTS failure.
3. `elm-format --validate src tests`. Never hand-align code; elm-format has no
   options by design.
4. `elm-review` with pinned rule packages, and `elm-test` (or `elm-test-rs
   --compiler "$(command -v elm)"`) on the same compiler version.
5. `nix build` as the canonical build.

A successful compile proves types, not behavior. Test decoders against real
payloads, including missing, `null` and wrong-typed fields.

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
- Annotate every top-level definition. Shadowing is a compile error: a
  parameter named like any top-level value (`status`, `title`, `model`) fails.

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

## Outdated patterns agents emit

| Wrong (0.18 or other languages) | Elm 0.19 |
|---|---|
| `Html.program`, `Html.beginnerProgram` | `Browser.element`, `Browser.sandbox` |
| `model ! [ cmd ]` | `( model, Cmd.batch [ cmd ] )` |
| `Http.send`, `Http.get url decoder` | `Http.get { url = u, expect = Http.expectJson GotX decoder }` |
| `toString x` | `String.fromInt`, `String.fromFloat`, or a hand-written `xToString` |
| `(,) a b`, 4-tuples | `Tuple.pair a b`; a record for 4+ fields |
| `x % n` | `modBy n x` (divisor first) |
| `Date`, `Time.Time` as a Float | `Time.Posix`, `Time.Zone` from `Time.here` |
| `Navigation.program`, `newUrl` | `Browser.application`, `Browser.Navigation.pushUrl key` |
| custom operators, `Native` modules | named functions; ports or custom elements |
| `{ model.sub \| x = 1 }` | bind `model.sub` in a `let`, then update it |
| a module named `Task`, `List`, `Dict`, ... | a domain name (`Card`); core names cause AMBIGUOUS IMPORT |

Read [mistakes](references/mistakes.md) for the full catalog with causes and
fixes: numeric types, `comparable` keys, recursion depth, DOM pitfalls,
interop and tooling.

## Dependencies

Add packages with `elm install author/package`, including packages that are
already indirect dependencies but are now imported directly. Set up tests
with `elm-test-rs init` (or `elm-test init`): in an application,
`elm install elm-explorations/test` wrongly lands in production
`dependencies`. Review the
`elm.json` diff instead of piping `yes` into prompts, never hand-edit
application dependency versions, and keep `elm-stuff/` out of version
control. Regenerate the Nix package sources whenever `elm.json` changes.

## Worked example

[examples/](examples/) is a small `Browser.element` board: decoded flags,
an opaque `CardId`, a `Remote` loading type, strict optional-field decoders, a
recursive decoder, an exhaustive kind list, a keyed list, a conditional
subscription and one tagged port. [default.nix](examples/default.nix) builds
it offline with nixpkgs' Elm and the official minifier settings, and
[Tests.elm](examples/tests/Tests.elm) runs under `elm-test-rs`.
