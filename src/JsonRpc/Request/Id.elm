module JsonRpc.Request.Id exposing (Id, encode, int, string, toId)

import Json.Encode as JE
import JsonRpc.Id as JsonRpcId


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


toId : Id -> JsonRpcId.Id
toId id =
    case id of
        Int n ->
            JsonRpcId.int n

        String s ->
            JsonRpcId.string s
