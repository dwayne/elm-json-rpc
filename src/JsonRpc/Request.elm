module JsonRpc.Request exposing
    ( Request
    , notification
    , request
    , toJson
    )

import Json.Encode as JE
import JsonRpc.Request.Id as Id exposing (Id)
import JsonRpc.Request.Params as Params exposing (Params)
import JsonRpc.Version as Version


type Request
    = Request
        { method : String
        , params : Params
        , id : Id
        }
    | Notification
        { method : String
        , params : Params
        }


request : String -> Params -> Id -> Request
request method params id =
    Request
        { method = method
        , params = params
        , id = id
        }


notification : String -> Params -> Request
notification method params =
    Notification
        { method = method
        , params = params
        }


toJson : Request -> JE.Value
toJson req =
    let
        jsonrpc =
            ( "jsonrpc", Version.toJson )
    in
    JE.object <|
        case req of
            Request { method, params, id } ->
                [ jsonrpc
                , ( "method", JE.string method )
                , ( "params", Params.toJson params )
                , ( "id", Id.toJson id )
                ]

            Notification { method, params } ->
                [ jsonrpc
                , ( "method", JE.string method )
                , ( "params", Params.toJson params )
                ]
