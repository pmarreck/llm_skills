# JSON decoders and encoders

Decoders are the boundary where untrusted data becomes typed data. Most Elm
runtime surprises happen here, because a decoder that compiles can still
accept the wrong data silently.

## Absent versus malformed

| Decoder | Field absent | `null` | Present, wrong type |
|---|---|---|---|
| `field "x" d` | fails | fails unless `d` accepts null | fails |
| `field "x" (nullable d)` | fails | `Nothing` | fails |
| `maybe (field "x" d)` | `Nothing` | `Nothing` | **`Nothing` (silent)** |
| `oneOf [ field "x" d, succeed v ]` | `v` | `v` | **`v` (silent)** |
| `DecodeField.optional "x" d` | `Nothing` | fails unless `d` accepts null | fails |
| `DecodeField.optionalNullable "x" d` | `Nothing` | `Nothing` | fails |

The two silent rows were verified with Elm 0.19.2 and 0.19.3 in
[Tests.elm](../examples/tests/Tests.elm). The danger compounds with lists: a
fallback around `field "subtasks" (list item)` erases every subtask when one
of them is malformed. Use the helpers in
[DecodeField.elm](../examples/src/DecodeField.elm) and apply a default
explicitly, only where the domain has one:

```elm
DecodeField.optional "subtasks" (Decode.list (Decode.lazy (\_ -> decoder)))
    |> Decode.map (Maybe.withDefault [])
```

*Researched:* `Json.Decode.Pipeline.optional` (NoRedInk/elm-json-decode-pipeline)
falls back on a missing field or `null`; check its current documentation for
how it treats a present field that fails to decode before relying on it.
`Json.Decode.Extra.optionalField` (elm-community/json-extra) targets the same
absent-versus-malformed distinction.

## Records

Use `Decode.map2` through `map8` for up to eight fields; they are in elm/json
and need no dependency. Beyond eight, either nest a sub-record or use a
pipeline style (`elm-json-decode-pipeline`, or `Json.Decode.Extra.andMap`).
Keep the constructor lambda's parameter names distinct from top-level names,
or the compiler reports SHADOWING.

A recursive record cannot be a type alias. Wrap it in a one-constructor custom
type (`type Card = Card { ..., subcards : List Card }`), which also makes it
opaque, and reach the fields through accessor functions.

## Tagged unions

Decode the tag, then choose the payload decoder with `andThen`, and fail on
unknown tags so new server variants surface as errors:

```elm
statusDecoder : Decoder Status
statusDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\tag ->
                case tag of
                    "todo" ->
                        Decode.succeed Todo

                    "blocked" ->
                        Decode.map Blocked (Decode.field "reason" Decode.string)

                    other ->
                        Decode.fail ("unknown status kind: " ++ other)
            )
```

Use `oneOf` for genuinely alternative shapes (a value that may be a number or
a numeric string), ordered from most specific to most permissive: the first
success wins, so a permissive decoder first masks the rest. Do not use
`andThen (\x -> succeed (f x))`; that is `map f`.

## Recursion

A decoder that refers to itself must do so through
`Decode.lazy (\_ -> decoder)`. Without it the definition can recurse forever
when evaluated ([bad recursion hint](https://github.com/elm/compiler/blob/main/hints/bad-recursion.md)).
Give recursive decoders a type annotation.

## Errors

Keep `Decode.Error` or `Http.Error` structured in the model and render it in
`view`. `Decode.errorToString` produces a multi-line message with the JSON
path and the offending value; `Http.BadBody` already carries that text for
`Http.expectJson`. Never collapse failures to "decode failed".

## Flags

Type flags as `Decode.Value` and decode them in `init`. A record-typed flag is
checked by the runtime, so a wrong shape throws in JavaScript before your code
runs. With a decoder, a bad flag becomes a state you render (see `BadFlags` in
[Main.elm](../examples/src/Main.elm)).

## Encoders and tests

Write each encoder beside its decoder. Test both:

- Example tests against real payloads: present, absent, `null`, wrong-typed,
  unknown tags, deeply nested data.
- A fuzz round trip, `decodeValue decoder (encode x) == Ok x`, for types that
  have an encoder. A round trip cannot catch both sides sharing the same
  mistake, so keep the example tests that pin the wire format.
