module Card exposing
    ( Card
    , CardId
    , Status(..)
    , StatusKind(..)
    , allKinds
    , assignee
    , decoder
    , id
    , idFromString
    , idToString
    , kind
    , kindLabel
    , status
    , subcards
    , title
    )

{-| A board card. The module is named `Card`, not `Task`: a local module named
after an elm/core module (`Task`, `List`, `Maybe`, `Dict`, ...) causes an
AMBIGUOUS IMPORT error wherever both are needed.
-}

import DecodeField
import Json.Decode as Decode exposing (Decoder)


{-| Opaque, so a card id cannot be confused with any other string.
-}
type CardId
    = CardId String


idFromString : String -> CardId
idFromString =
    CardId


idToString : CardId -> String
idToString (CardId raw) =
    raw


type Status
    = Todo
    | Doing
    | Blocked String


{-| Status without its payload, for grouping and column headers. Grouping on
this instead of on `Status` avoids placeholder values such as `Blocked ""`.
-}
type StatusKind
    = TodoKind
    | DoingKind
    | BlockedKind


kind : Status -> StatusKind
kind cardStatus =
    case cardStatus of
        Todo ->
            TodoKind

        Doing ->
            DoingKind

        Blocked _ ->
            BlockedKind


{-| Every kind, in column order. Built from `nextKind`, whose `case` is
exhaustive: adding a constructor fails to compile until it is placed in the
chain, so this list cannot silently miss a kind.
-}
allKinds : List StatusKind
allKinds =
    let
        collect : StatusKind -> List StatusKind -> List StatusKind
        collect k acc =
            case nextKind k of
                Just following ->
                    collect following (k :: acc)

                Nothing ->
                    List.reverse (k :: acc)
    in
    collect TodoKind []


nextKind : StatusKind -> Maybe StatusKind
nextKind k =
    case k of
        TodoKind ->
            Just DoingKind

        DoingKind ->
            Just BlockedKind

        BlockedKind ->
            Nothing


kindLabel : StatusKind -> String
kindLabel k =
    case k of
        TodoKind ->
            "To do"

        DoingKind ->
            "Doing"

        BlockedKind ->
            "Blocked"


{-| A recursive record cannot be a type alias, so the record is wrapped in a
one-constructor custom type, which also keeps it opaque.
-}
type Card
    = Card
        { id : CardId
        , title : String
        , status : Status
        , assignee : Maybe String
        , subcards : List Card
        }


id : Card -> CardId
id (Card c) =
    c.id


title : Card -> String
title (Card c) =
    c.title


status : Card -> Status
status (Card c) =
    c.status


assignee : Card -> Maybe String
assignee (Card c) =
    c.assignee


subcards : Card -> List Card
subcards (Card c) =
    c.subcards


decoder : Decoder Card
decoder =
    Decode.map5
        (\cardId cardTitle cardStatus cardAssignee children ->
            Card
                { id = cardId
                , title = cardTitle
                , status = cardStatus
                , assignee = cardAssignee
                , subcards = children
                }
        )
        (Decode.field "id" (Decode.map CardId Decode.string))
        (Decode.field "title" Decode.string)
        (Decode.field "status" statusDecoder)
        (DecodeField.optionalNullable "assignee" Decode.string)
        -- Absent means no subcards; a malformed subcard fails the decode
        -- instead of silently erasing the whole list.
        (DecodeField.optional "subtasks" (Decode.list (Decode.lazy (\_ -> decoder)))
            |> Decode.map (Maybe.withDefault [])
        )


statusDecoder : Decoder Status
statusDecoder =
    Decode.field "kind" Decode.string
        |> Decode.andThen
            (\tag ->
                case tag of
                    "todo" ->
                        Decode.succeed Todo

                    "doing" ->
                        Decode.succeed Doing

                    "blocked" ->
                        Decode.map Blocked (Decode.field "reason" Decode.string)

                    other ->
                        Decode.fail ("unknown status kind: " ++ other)
            )
