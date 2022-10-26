module JsonRpc.Response.Id exposing
    ( Id
    , decoder
    , int
    , null
    , string
    )

import Json.Decode as JD


type Id
    = String String
    | Int Int
    | Null


string : String -> Id
string =
    String


int : Int -> Id
int =
    Int


null : Id
null =
    Null


decoder : JD.Decoder Id
decoder =
    JD.oneOf
        [ JD.map String JD.string
        , JD.map Int JD.int
        , JD.null Null
        ]
