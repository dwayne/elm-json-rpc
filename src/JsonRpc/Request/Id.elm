module JsonRpc.Request.Id exposing
    ( Id
    , int
    , string
    , toJson
    , toString
    )

import Json.Encode as JE


type Id
    = Int Int
    | String String


int : Int -> Id
int =
    Int


string : String -> Id
string =
    String


toString : Id -> String
toString id =
    case id of
        Int n ->
            String.fromInt n

        String s ->
            "\"" ++ s ++ "\""


toJson : Id -> JE.Value
toJson id =
    case id of
        Int n ->
            JE.int n

        String s ->
            JE.string s
