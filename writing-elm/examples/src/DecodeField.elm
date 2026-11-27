module DecodeField exposing (optional, optionalNullable)

{-| Optional JSON fields that still reject wrong data.

`Json.Decode.maybe` and `oneOf [ field ..., succeed default ]` turn a field
that is present but malformed into `Nothing` or the default, silently. These
helpers only fall back when the field is absent; a present field must decode.

-}

import Json.Decode as Decode exposing (Decoder)


{-| Absent gives `Nothing`; present must decode with the given decoder.
-}
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


{-| Absent or `null` gives `Nothing`; any other value must decode.
-}
optionalNullable : String -> Decoder a -> Decoder (Maybe a)
optionalNullable name valueDecoder =
    optional name (Decode.nullable valueDecoder)
        |> Decode.map (Maybe.andThen identity)
