module JsonRpc exposing
    ( Request, Params, Param, noParams, positionalParams, keywordParams
    , send
    , Id, intId, stringId, sendWithId
    , Options, defaultOptions, sendCustom
    , Error(..), HttpError(..), Kind(..)
    )

{-| Send JSON-RPC 2.0 requests over HTTP.


# Construct a request

@docs Request, Params, Param, noParams, positionalParams, keywordParams


# Send a request

@docs send


# Send a request with a custom identifier

@docs Id, intId, stringId, sendWithId


# Advanced

@docs Options, defaultOptions, sendCustom


# Error

@docs Error, HttpError, Kind

-}

import Http
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Id as RequestId
import JsonRpc.Request.Params as RequestParams
import JsonRpc.Response.Error as ResponseError
import JsonRpc.Transport.Http as JsonRpcHttp



-- PARAMS


{-| A JSON Array or Object that holds the parameter values to be used during
invocation of an RPC method.
-}
type Params
    = Params RequestParams.Params


{-| A JSON value.
-}
type alias Param =
    JE.Value


{-| An empty JSON Array.
-}
noParams : Params
noParams =
    Params RequestParams.empty


{-| A JSON Array containing the parameter values in the Server expected order.

For example, the following:

    import Json.Encode as JE
    import JsonRpc

    JsonRpc.positionalParams
        [ JE.string "0x0000000000000000000000000000000000000000"
        , JE.string "latest"
        ]

represents the JSON Array:

    [ "0x0000000000000000000000000000000000000000", "latest" ]

-}
positionalParams : List Param -> Params
positionalParams =
    Params << RequestParams.byPosition


{-| A JSON Object with member names that match the Server expected parameter
names.

For example, the following:

    import Json.Encode as JE
    import JsonRpc

    JsonRpc.keywordParams
        [ ( "apiKey", JE.string "YOUR API KEY"
        , ( "n", JE.int 5 )
        , ( "min", JE.int 1 )
        , ( "max", JE.int 10 )
        ]
        [ ( "replacement", Just False )
        ]

represents the JSON Object:

    {
        "apiKey": "YOUR API KEY",
        "n": 5,
        "min": 1,
        "max": 10,
        "replacement": false
    }

-}
keywordParams : List ( String, Param ) -> List ( String, Maybe Param ) -> Params
keywordParams required optional =
    Params <| RequestParams.byName required optional



-- ID


{-| -}
type Id
    = Id RequestId.Id


{-| -}
intId : Int -> Id
intId =
    Id << RequestId.int


{-| -}
stringId : String -> Id
stringId =
    Id << RequestId.string



-- TRANSPORT: HTTP


{-| An RPC call is represented by sending a [Request object](https://www.jsonrpc.org/specification#request_object)
to a server. This `Request` record is used to create a Request object.

  - `method` contains the name of the method to be invoked
  - `params` holds the parameter values to be used during the invocation of the
    method
  - `result` is the JSON decoder used to decode the _result_ field of a successful
    [Response object](https://www.jsonrpc.org/specification#response_object)

For example, the following `Request` record:

    import Json.Decode as JD
    import Json.Encode as JE
    import JsonRpc

    getBalance : JsonRpc.Request String
    getBalance =
        { method = "eth_getBalance"
        , params =
            JsonRpc.positionalParams
                [ JE.string "0x0000000000000000000000000000000000000000"
                , JE.string "latest"
                ]
        , result = JD.string
        }

corresponds to the following Request object:

    {
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [ "0x0000000000000000000000000000000000000000", "latest" ],
        "id": ...
    }

On a successful response the _result_ field is expected to contain a `String`.

**Note:** The _id_ field is set when sending the request.

-}
type alias Request result =
    { method : String
    , params : Params
    , result : JD.Decoder result
    }


{-| -}
type Error
    = HttpError HttpError
    | UnexpectedStatus Http.Metadata String
    | DecodeError JD.Error
    | MismatchedIds
        { requestId : String
        , responseId : String
        }
    | JsonRpcError
        { kind : Kind
        , code : Int
        , message : String
        , maybeData : Maybe JE.Value
        , responseId : String
        }


{-| -}
type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String


{-| -}
type Kind
    = ParseError
    | InvalidRequest
    | MethodNotFound
    | InvalidParams
    | InternalError
    | ServerError
    | ReservedError
    | ApplicationError


{-| -}
type alias Options =
    { headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


{-| -}
defaultOptions : Options
defaultOptions =
    { headers = []
    , timeout = Nothing
    , tracker = Nothing
    }


{-| -}
send :
    String
    -> (Result Error result -> msg)
    -> Request result
    -> Cmd msg
send url toMsg =
    sendCustom defaultOptions url toMsg defaultId


defaultId : Id
defaultId =
    Id <| RequestId.int 1


{-| -}
sendWithId :
    String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendWithId url toMsg =
    sendCustom defaultOptions url toMsg


{-| -}
sendCustom :
    Options
    -> String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendCustom options url toMsg (Id id) request =
    let
        internalToMsg =
            toMsg << Result.mapError fromInternalError

        (Params internalParams) =
            request.params

        internalRequest =
            { method = request.method
            , params = internalParams
            , dataDecoder = JD.value
            , answerDecoder = request.result
            }

        fromInternalError error =
            case error of
                JsonRpcHttp.HttpError httpError ->
                    HttpError <| fromInternalHttpError httpError

                JsonRpcHttp.UnexpectedStatus metadata s ->
                    UnexpectedStatus metadata s

                JsonRpcHttp.DecodeError decodeError ->
                    DecodeError decodeError

                JsonRpcHttp.MismatchedIds ids ->
                    MismatchedIds ids

                JsonRpcHttp.JsonRpcError { kind, code, message, maybeData, responseId } ->
                    JsonRpcError
                        { kind = fromInternalKind kind
                        , code = code
                        , message = message
                        , maybeData = maybeData
                        , responseId = responseId
                        }

        fromInternalHttpError httpError =
            case httpError of
                JsonRpcHttp.BadUrl s ->
                    BadUrl s

                JsonRpcHttp.Timeout ->
                    Timeout

                JsonRpcHttp.NetworkError ->
                    NetworkError

                JsonRpcHttp.BadStatus metadata s ->
                    BadStatus metadata s

        fromInternalKind kind =
            case kind of
                ResponseError.ParseError ->
                    ParseError

                ResponseError.InvalidRequest ->
                    InvalidRequest

                ResponseError.MethodNotFound ->
                    MethodNotFound

                ResponseError.InvalidParams ->
                    InvalidParams

                ResponseError.InternalError ->
                    InternalError

                ResponseError.ServerError ->
                    ServerError

                ResponseError.ReservedError ->
                    ReservedError

                ResponseError.ApplicationError ->
                    ApplicationError
    in
    JsonRpcHttp.send options url internalToMsg id internalRequest
