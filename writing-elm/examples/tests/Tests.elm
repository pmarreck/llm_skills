module Tests exposing (suite)

import Card
import Expect
import Fuzz
import Json.Decode as Decode
import Test exposing (Test, describe, fuzz, test)


decodeCard : String -> Result Decode.Error Card.Card
decodeCard =
    Decode.decodeString Card.decoder


cardJson : String -> String
cardJson extraFields =
    """{"id": "c1", "title": "Ship", "status": {"kind": "todo"}""" ++ extraFields ++ "}"


isErr : Result e a -> Bool
isErr result =
    case result of
        Ok _ ->
            False

        Err _ ->
            True


suite : Test
suite =
    describe "Card.decoder"
        [ test "absent assignee decodes to Nothing" <|
            \_ -> decodeCard (cardJson "") |> Result.map Card.assignee |> Expect.equal (Ok Nothing)
        , test "null assignee decodes to Nothing" <|
            \_ -> decodeCard (cardJson ""","assignee": null""") |> Result.map Card.assignee |> Expect.equal (Ok Nothing)
        , test "present assignee decodes" <|
            \_ -> decodeCard (cardJson ""","assignee": "ana\"""") |> Result.map Card.assignee |> Expect.equal (Ok (Just "ana"))
        , test "wrong-typed assignee fails instead of becoming Nothing" <|
            \_ -> decodeCard (cardJson ""","assignee": 42""") |> isErr |> Expect.equal True
        , test "absent subtasks decode to an empty list" <|
            \_ -> decodeCard (cardJson "") |> Result.map (Card.subcards >> List.length) |> Expect.equal (Ok 0)
        , test "nested subtasks decode recursively" <|
            \_ ->
                decodeCard (cardJson (""","subtasks": [""" ++ cardJson (""","subtasks": [""" ++ cardJson "" ++ "]") ++ "]"))
                    |> Result.map (Card.subcards >> List.concatMap Card.subcards >> List.length)
                    |> Expect.equal (Ok 1)
        , test "a malformed subtask fails instead of erasing the list" <|
            \_ -> decodeCard (cardJson ""","subtasks": [{"id": "c2"}]""") |> isErr |> Expect.equal True
        , test "blocked carries its reason" <|
            \_ ->
                Decode.decodeString Card.decoder """{"id": "c1", "title": "x", "status": {"kind": "blocked", "reason": "waiting"}}"""
                    |> Result.map Card.status
                    |> Expect.equal (Ok (Card.Blocked "waiting"))
        , test "unknown status kind fails" <|
            \_ ->
                Decode.decodeString Card.decoder """{"id": "c1", "title": "x", "status": {"kind": "done"}}"""
                    |> isErr
                    |> Expect.equal True
        , test "allKinds lists every kind in column order" <|
            \_ -> Card.allKinds |> Expect.equal [ Card.TodoKind, Card.DoingKind, Card.BlockedKind ]
        , fuzz Fuzz.string "card ids round-trip through strings" <|
            \raw -> Card.idFromString raw |> Card.idToString |> Expect.equal raw
        , describe "the trap DecodeField avoids"
            [ test "Decode.maybe turns a wrong-typed field into Nothing" <|
                \_ ->
                    Decode.decodeString (Decode.maybe (Decode.field "n" Decode.int)) """{"n": "oops"}"""
                        |> Expect.equal (Ok Nothing)
            , test "oneOf with a fallback swallows a malformed list" <|
                \_ ->
                    Decode.decodeString
                        (Decode.oneOf [ Decode.field "xs" (Decode.list Decode.int), Decode.succeed [] ])
                        """{"xs": [1, "two"]}"""
                        |> Expect.equal (Ok [])
            ]
        ]
