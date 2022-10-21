module JsonRpc.Request.Id exposing (Id, encode, int, string)

import Json.Encode as JE


type Id
    = String String
    | Int Int


string : String -> Id
string =
    String


int : Int -> Id
int =
    Int


encode : Id -> JE.Value
encode id =
    case id of
        String s ->
            JE.string s

        Int n ->
            JE.int n
