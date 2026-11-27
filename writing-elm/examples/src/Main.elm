module Main exposing (main)

import Browser
import Card exposing (Card, StatusKind)
import DecodeField
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Keyed
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports
import Time


{-| Flags arrive as raw JSON and are decoded, never trusted: a wrong shape
becomes a visible error state instead of a JavaScript exception at startup.
-}
type alias Flags =
    { apiBase : String
    , theme : Theme
    }


type Theme
    = Light
    | Dark


flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.map2 Flags
        (Decode.field "apiBase" Decode.string)
        (DecodeField.optional "theme" themeDecoder
            |> Decode.map (Maybe.withDefault Light)
        )


themeDecoder : Decoder Theme
themeDecoder =
    Decode.string
        |> Decode.andThen
            (\name ->
                case name of
                    "light" ->
                        Decode.succeed Light

                    "dark" ->
                        Decode.succeed Dark

                    other ->
                        Decode.fail ("unknown theme: " ++ other)
            )


{-| One custom type instead of `loading : Bool`, `error : Maybe String` and
`cards : Maybe (List Card)`, so impossible combinations cannot be built.
-}
type Remote a
    = Loading
    | Failed Http.Error
    | Loaded a


type Model
    = BadFlags Decode.Error
    | Running Session


type alias Session =
    { theme : Theme
    , cards : Remote (List Card)
    , filterText : String -- exactly what the user typed; normalized on use
    , timer : Timer
    }


type Timer
    = Paused Int
    | Ticking Int


type Msg
    = GotCards (Result Http.Error (List Card))
    | FilterTyped String
    | TimerToggled
    | Tick Time.Posix


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Decode.Value -> ( Model, Cmd Msg )
init rawFlags =
    case Decode.decodeValue flagsDecoder rawFlags of
        Ok flags ->
            ( Running { theme = flags.theme, cards = Loading, filterText = "", timer = Paused 0 }
            , Http.get
                { url = flags.apiBase ++ "/tasks"
                , expect = Http.expectJson GotCards (Decode.list Card.decoder)
                }
            )

        Err error ->
            ( BadFlags error, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        BadFlags _ ->
            ( model, Cmd.none )

        Running session ->
            updateSession msg session
                |> Tuple.mapFirst Running


updateSession : Msg -> Session -> ( Session, Cmd Msg )
updateSession msg session =
    case msg of
        GotCards (Ok cards) ->
            ( { session | cards = Loaded cards }, Cmd.none )

        GotCards (Err error) ->
            ( { session | cards = Failed error }, Cmd.none )

        FilterTyped text ->
            ( { session | filterText = text }
            , Ports.send "saveFilter" (Encode.string (normalize text))
            )

        TimerToggled ->
            ( { session | timer = toggle session.timer }, Cmd.none )

        Tick _ ->
            ( { session | timer = advance session.timer }, Cmd.none )


toggle : Timer -> Timer
toggle timer =
    case timer of
        Paused seconds ->
            Ticking seconds

        Ticking seconds ->
            Paused seconds


advance : Timer -> Timer
advance timer =
    case timer of
        Ticking seconds ->
            Ticking (seconds + 1)

        Paused _ ->
            timer


normalize : String -> String
normalize =
    String.trim >> String.toLower


{-| Subscribed only while ticking; returning `Sub.none` is how a subscription
stops. There is no separate unsubscribe call.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Running { timer } ->
            case timer of
                Ticking _ ->
                    Time.every 1000 Tick

                Paused _ ->
                    Sub.none

        BadFlags _ ->
            Sub.none


view : Model -> Html Msg
view model =
    case model of
        BadFlags error ->
            Html.pre [] [ Html.text ("Invalid flags:\n" ++ Decode.errorToString error) ]

        Running session ->
            Html.div [ Attr.class (themeClass session.theme) ]
                [ Html.input
                    [ Attr.placeholder "Filter"
                    , Attr.value session.filterText
                    , Events.onInput FilterTyped
                    ]
                    []
                , Html.button [ Events.onClick TimerToggled ] [ Html.text (timerLabel session.timer) ]
                , viewCards (normalize session.filterText) session.cards
                ]


themeClass : Theme -> String
themeClass theme =
    case theme of
        Light ->
            "theme-light"

        Dark ->
            "theme-dark"


timerLabel : Timer -> String
timerLabel timer =
    case timer of
        Paused seconds ->
            "Start (" ++ String.fromInt seconds ++ "s)"

        Ticking seconds ->
            "Pause (" ++ String.fromInt seconds ++ "s)"


viewCards : String -> Remote (List Card) -> Html Msg
viewCards query remote =
    case remote of
        Loading ->
            Html.text "Loading..."

        Failed error ->
            Html.text ("Could not load cards: " ++ httpErrorToString error)

        Loaded cards ->
            let
                visible =
                    List.filter (String.contains query << String.toLower << Card.title) cards
            in
            Html.div [] (List.map (viewColumn visible) Card.allKinds)


viewColumn : List Card -> StatusKind -> Html Msg
viewColumn cards columnKind =
    let
        inColumn =
            List.filter (\card -> Card.kind (Card.status card) == columnKind) cards
    in
    Html.section []
        [ Html.h2 [] [ Html.text (Card.kindLabel columnKind ++ " (" ++ String.fromInt (List.length inColumn) ++ ")") ]

        -- Keyed by card id so reordering keeps each row's DOM state.
        , Html.Keyed.ul [] (List.map (\card -> ( Card.idToString (Card.id card), Html.li [] [ Html.text (Card.title card) ] )) inColumn)
        ]


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "bad URL " ++ url

        Http.Timeout ->
            "the request timed out"

        Http.NetworkError ->
            "network error"

        Http.BadStatus code ->
            "server returned status " ++ String.fromInt code

        Http.BadBody details ->
            "unexpected response: " ++ details
