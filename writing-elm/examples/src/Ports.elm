port module Ports exposing (send)

{-| One outgoing port carrying tagged JSON messages, rather than one port per
JavaScript function. JavaScript dispatches on the "tag" field.
-}

import Json.Encode as Encode


port toJs : Encode.Value -> Cmd msg


send : String -> Encode.Value -> Cmd msg
send tag payload =
    toJs (Encode.object [ ( "tag", Encode.string tag ), ( "payload", payload ) ])
