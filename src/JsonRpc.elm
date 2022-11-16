module JsonRpc exposing
    ( Request, Params, Param, noParams, positionalParams, keywordParams
    , send
    , Id, intId, stringId, sendWithId
    , HttpOptions, defaultHttpOptions, sendCustom
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

@docs HttpOptions, defaultHttpOptions, sendCustom


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


{-| An identifier established by the Client.
-}
type Id
    = Id RequestId.Id


{-| An integer identifier.
-}
intId : Int -> Id
intId =
    Id << RequestId.int


{-| A string identifier. Maybe you'd want to use a UUID as your identifier.

    import JsonRpc

    JsonRpc.stringId "789e08a1-6156-4046-88b6-5b96a87a2eba"

-}
stringId : String -> Id
stringId =
    Id << RequestId.string



-- TRANSPORT: HTTP


{-| An RPC call is represented by sending a [Request object](https://www.jsonrpc.org/specification#request_object)
to a server. This [`Request`](#Request) record is used to create a Request object.

  - `method` contains the name of the method to be invoked.
  - `params` holds the parameter values to be used during the invocation of the
    method.
  - `result` is the JSON decoder used to decode the _result_ field of a successful
    [Response object](https://www.jsonrpc.org/specification#response_object).

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


{-| A request can fail in multiple ways.

  - `HttpError` means there was an error trying to reach the server and the
    underlying [`HttpError`](#HttpError) will tell you why.
  - `UnexpectedStatus` means the [successful HTTP status code](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#successful_responses)
    returned by the server was not 200. In other words, it was in the 200 to 299
    range, maybe it was 202 or 204 but not 200.
  - `DecodeError` means the [Response object](https://www.jsonrpc.org/specification#response_object)
    returned by the server was malformed.
  - `MismatchedIds` means the _id_ of the [Request object](https://www.jsonrpc.org/specification#request_object)
    is not the same as the _id_ of the [Response object](https://www.jsonrpc.org/specification#response_object).
  - `JsonRpcError` means the RPC call encountered an error. The `maybeData`
    field may contain detailed error information as defined by the server.

-}
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


{-| The HTTP transport can fail in multiple ways.

  - `BadUrl` means you did not provide a valid URL.
  - `Timeout` means it took too long to get a response.
  - `NetworkError` means the user turned off their wifi, went in a cave, etc.
  - `BadStatus` means you got a response back, but the status code indicates
    failure.

-}
type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String


{-| Categorizes the error code of a failed RPC call.

The categories are derived from the specification as given by the table under
the [Error object](https://www.jsonrpc.org/specification#error_object) section.

-}
type Kind
    = ParseError
    | InvalidRequest
    | MethodNotFound
    | InvalidParams
    | InternalError
    | ServerError
    | ReservedError
    | ApplicationError


{-| The HTTP options you're allowed to modify.

  - `headers` are the extra HTTP headers you'd like to add. The
    `Content-Type: application/json` and `Accept: application/json` headers are
    always automatically added.
  - `timeout` is the number of milliseconds you are willing to wait before giving
    up.
  - `tracker` lets you [cancel](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#cancel)
    and [track](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#track)
    requests.

-}
type alias HttpOptions =
    { headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


{-| The default HTTP options used by [`send`](#send) and [`sendWithId`](#sendWithId).

    { headers = []
    , timeout = Nothing
    , tracker = Nothing
    }

-}
defaultHttpOptions : HttpOptions
defaultHttpOptions =
    { headers = []
    , timeout = Nothing
    , tracker = Nothing
    }


{-| Sends a Request object over HTTP to a JSON-RPC Server with a default request
identifier of 1.

    import JsonRpc

    type Msg
        = GotBalance (Result JsonRpc.Error String)

    let
        rpcUrl =
            "https://eth-goerli.public.blastapi.io"
    in
    JsonRpc.send rpcUrl GotBalance getBalance

The Request object:

    {
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": [ "0x0000000000000000000000000000000000000000", "latest" ],
        "id": 1
    }

will be sent over HTTP to the JSON-RPC Server at the endpoint
`https://eth-goerli.public.blastapi.io`.

-}
send :
    String
    -> (Result Error result -> msg)
    -> Request result
    -> Cmd msg
send url toMsg =
    sendCustom defaultHttpOptions url toMsg defaultId


defaultId : Id
defaultId =
    Id <| RequestId.int 1


{-| Just like [`send`](#send), but it allows you to set the identifier.
-}
sendWithId :
    String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendWithId url toMsg =
    sendCustom defaultHttpOptions url toMsg


{-| Just like [`sendWithId`](#sendWithId), but it allows you to customize the
HTTP options.

    import JsonRpc exposing (defaultHttpOptions)

    type Msg
        = GotBalance (Result JsonRpc.Error String)

    let
        httpOptions =
            -- wait 1 minute
            { defaultHttpOptions | timeout = Just 60000 }

        rpcUrl =
            "https://eth-goerli.public.blastapi.io"

        id =
            JsonRpc.stringId "abc123"
    in
    JsonRpc.sendCustom httpOptions rpcUrl GotBalance id getBalance

-}
sendCustom :
    HttpOptions
    -> String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendCustom httpOptions url toMsg (Id id) request =
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
    JsonRpcHttp.send httpOptions url internalToMsg id internalRequest
