module JsonRpc.Request exposing (Request, encode, notification, request)

import Json.Encode as JE
import JsonRpc.Request.Id as Id exposing (Id)
import JsonRpc.Request.Params as Params exposing (Params)
import JsonRpc.Version as Version


type Request
    = Request
        { method : String
        , maybeParams : Maybe Params
        , id : Id
        }
    | Notification
        { method : String
        , maybeParams : Maybe Params
        }


request : String -> Maybe Params -> Id -> Request
request method maybeParams id =
    Request
        { method = method
        , maybeParams = maybeParams
        , id = id
        }


notification : String -> Maybe Params -> Request
notification method maybeParams =
    Notification
        { method = method
        , maybeParams = maybeParams
        }


encode : Request -> JE.Value
encode req =
    let
        jsonrpc =
            Just ( "jsonrpc", Version.encode )

        toParamsField params =
            ( "params", Params.encode params )

        list =
            case req of
                Request { method, maybeParams, id } ->
                    [ jsonrpc
                    , Just ( "method", JE.string method )
                    , Maybe.map toParamsField maybeParams
                    , Just ( "id", Id.encode id )
                    ]

                Notification { method, maybeParams } ->
                    [ jsonrpc
                    , Just ( "method", JE.string method )
                    , Maybe.map toParamsField maybeParams
                    ]
    in
    list
        |> List.filterMap identity
        |> JE.object
