module JsonRpc.Internal.Response.Id exposing
    ( Id
    , decoder
    , int
    , null
    , string
    , toString
    )

import Json.Decode as JD


type Id
    = Int Int
    | String String
    | Null


int : Int -> Id
int =
    Int


string : String -> Id
string =
    String


null : Id
null =
    Null


decoder : JD.Decoder Id
decoder =
    JD.oneOf
        [ JD.map Int JD.int
        , JD.map String JD.string
        , JD.null Null
        ]


toString : Id -> String
toString id =
    case id of
        Int n ->
            String.fromInt n

        String s ->
            "\"" ++ s ++ "\""

        Null ->
            "null"
