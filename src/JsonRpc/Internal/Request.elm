module JsonRpc.Internal.Request exposing
    ( Request
    , encode
    , notification
    , request
    )

import Json.Encode as JE
import JsonRpc.Internal.Request.Id as Id exposing (Id)
import JsonRpc.Internal.Request.Params as Params exposing (Params)
import JsonRpc.Internal.Version as Version


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


encode : Request -> JE.Value
encode req =
    let
        jsonrpc =
            ( "jsonrpc", Version.encode )
    in
    JE.object <|
        case req of
            Request { method, params, id } ->
                [ jsonrpc
                , ( "method", JE.string method )
                , ( "params", Params.encode params )
                , ( "id", Id.encode id )
                ]

            Notification { method, params } ->
                [ jsonrpc
                , ( "method", JE.string method )
                , ( "params", Params.encode params )
                ]
