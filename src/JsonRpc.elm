module JsonRpc exposing
    ( Error(..)
    , HttpError(..)
    , Id
    , Kind(..)
    , Options
    , Param
    , Params
    , Request
    , defaultId
    , defaultOptions
    , empty
    , intId
    , keywordParams
    , params
    , send
    , sendCustom
    , sendWithId
    , stringId
    )

import Http
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Id as RequestId
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


keywordParams : List ( String, Param ) -> List ( String, Maybe Param ) -> Params
keywordParams =
    RequestParams.byName



-- ID


type alias Id =
    RequestId.Id


defaultId : Id
defaultId =
    RequestId.int 1


intId : Int -> Id
intId =
    RequestId.int


stringId : String -> Id
stringId =
    RequestId.string



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


type alias Options =
    JsonRpcHttp.Options


defaultOptions : Options
defaultOptions =
    { headers = []
    , timeout = Nothing
    , tracker = Nothing
    }


send :
    String
    -> (Result Error result -> msg)
    -> Request result
    -> Cmd msg
send url toMsg =
    sendCustom defaultOptions url toMsg defaultId


sendWithId :
    String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendWithId url toMsg =
    sendCustom defaultOptions url toMsg


sendCustom :
    Options
    -> String
    -> (Result Error result -> msg)
    -> Id
    -> Request result
    -> Cmd msg
sendCustom options url toMsg id request =
    let
        internalToMsg =
            toMsg << Result.mapError fromInternalError

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
    JsonRpcHttp.send options url internalToMsg id internalRequest
