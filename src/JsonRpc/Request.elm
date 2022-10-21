module JsonRpc.Request exposing (Request, encode, request)

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


request : String -> Maybe Params -> Id -> Request
request method maybeParams id =
    Request
        { method = method
        , maybeParams = maybeParams
        , id = id
        }


encode : Request -> JE.Value
encode req =
    let
        toParamsField params =
            ( "params", Params.encode params )
    in
    case req of
        Request { method, maybeParams, id } ->
            let
                fields =
                    [ Just ( "jsonrpc", Version.encode )
                    , Just ( "method", JE.string method )
                    , Maybe.map toParamsField maybeParams
                    , Just ( "id", Id.encode id )
                    ]
            in
            fields
                |> List.filterMap identity
                |> JE.object
