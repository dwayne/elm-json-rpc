module JsonRpc exposing
    ( Error(..)
    , HttpError(..)
    , Kind(..)
    , Options
    , Param
    , Params
    , Request
    , empty
    , keywordParams
    , params
    , send
    )

import Http
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Params as RequestParams
import JsonRpc.Response.Error as ResponseError
import JsonRpc.Transport.Http as JsonRpcHttp



-- PARAMS


type alias Params =
    RequestParams.Params


type alias Param =
    RequestParams.Param


empty : Params
empty =
    RequestParams.empty


params : List Param -> Params
params =
    RequestParams.byPosition


keywordParams : ( String, Param ) -> List ( String, Param ) -> Params
keywordParams =
    RequestParams.byName



-- TRANSPORT: HTTP


type alias Request result =
    { method : String
    , params : Params
    , result : JD.Decoder result
    }


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


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String


type Kind
    = ParseError
    | InvalidRequest
    | MethodNotFound
    | InvalidParams
    | InternalError
    | ServerError
    | ReservedError
    | ApplicationError


type alias Options result msg =
    { url : String
    , toMsg : Result Error result -> msg
    , headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


send : Options result msg -> Request result -> Cmd msg
send { url, toMsg, headers, timeout, tracker } request =
    let
        internalOptions =
            { url = url
            , toMsg = toMsg << Result.mapError fromInternalError
            , headers = headers
            , timeout = timeout
            , tracker = tracker
            }

        internalRequest =
            { method = request.method
            , params = request.params
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
    JsonRpcHttp.send internalOptions internalRequest
