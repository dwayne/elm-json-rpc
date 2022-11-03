module JsonRpc.Advanced exposing
    ( Error(..)
    , HttpError(..)
    , Kind(..)
    , Options
    , Params
    , Param
    , Request
    , emptyParams
    , keywordParams
    , positionalParams
    , send
    )

import Http
import Json.Decode as JD
import JsonRpc.Internal.Request.Params as RequestParams
import JsonRpc.Internal.Response.Error as ResponseError
import JsonRpc.Internal.Transport.Http as JsonRpcHttp



-- PARAMS


type alias Params =
    RequestParams.Params


type alias Param =
    RequestParams.Param


emptyParams : Params
emptyParams =
    RequestParams.empty


positionalParams : List Param -> Params
positionalParams =
    RequestParams.byPosition


keywordParams : ( String, Param ) -> List ( String, Param ) -> Params
keywordParams =
    RequestParams.byName



-- TRANSPORT: HTTP


type alias Request data answer =
    JsonRpcHttp.Request data answer


type Error data
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
        , maybeData : Maybe data
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


type alias Options data answer msg =
    { url : String
    , toMsg : Result (Error data) answer -> msg
    , headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


send : Options data answer msg -> Request data answer -> Cmd msg
send { url, toMsg, headers, timeout, tracker } =
    let
        internalOptions =
            { url = url
            , toMsg = toMsg << Result.mapError fromInternalError
            , headers = headers
            , timeout = timeout
            , tracker = tracker
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
    JsonRpcHttp.send internalOptions
