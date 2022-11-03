module JsonRpc.Internal.Request.Id exposing
    ( Id
    , encode
    , int
    , string
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


encode : Id -> JE.Value
encode id =
    case id of
        Int n ->
            JE.int n

        String s ->
            JE.string s


toString : Id -> String
toString id =
    case id of
        Int n ->
            String.fromInt n

        String s ->
            "\"" ++ s ++ "\""