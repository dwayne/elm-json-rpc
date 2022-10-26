module JsonRpc.Response.Id exposing (Id, decoder)

import Json.Decode as JD


type Id
    = String String
    | Int Int
    | Null


decoder : JD.Decoder Id
decoder =
    JD.oneOf
        [ JD.map String JD.string
        , JD.map Int JD.int
        , JD.null Null
        ]
