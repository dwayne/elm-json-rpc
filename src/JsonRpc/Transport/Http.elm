module JsonRpc.Transport.Http exposing
    ( Error(..)
    , HttpError(..)
    , Request
    , SendOptions
    , defaultSendOptions
    , send
    , sendDefault
    )

import Http
import Json.Decode as JD
import JsonRpc.Id as Id exposing (Id)
import JsonRpc.Request as Request
import JsonRpc.Request.Id as RequestId
import JsonRpc.Request.Params exposing (Params)
import JsonRpc.Response as Response
import JsonRpc.Response.Error as ResponseError exposing (ErrorObject)


type alias Request data answer =
    { method : String
    , params : Params
    , dataDecoder : JD.Decoder data
    , answerDecoder : JD.Decoder answer
    }


type Error data
    = HttpError HttpError
    | UnexpectedStatus Http.Metadata String
    | DecodeError JD.Error
    | MismatchedIds
        { requestId : Id
        , responseId : Id
        }
    | JsonRpcError
        { errorObject : ErrorObject data
        , responseId : Id
        }


type HttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String


type alias SendOptions =
    { headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


defaultSendOptions : SendOptions
defaultSendOptions =
    { headers = []
    , timeout = Nothing
    , tracker = Nothing
    }


sendDefault :
    String
    -> (Result (Error data) answer -> msg)
    -> Request data answer
    -> Cmd msg
sendDefault =
    send defaultSendOptions


send :
    SendOptions
    -> String
    -> (Result (Error data) answer -> msg)
    -> Request data answer
    -> Cmd msg
send options url toMsg { method, params, dataDecoder, answerDecoder } =
    let
        id =
            RequestId.int 1

        body =
            Request.request method params id
                |> Request.encode
                |> Http.jsonBody

        expect =
            handleRequest dataDecoder answerDecoder id
                |> Http.expectStringResponse toMsg
    in
    Http.request
        { method = "POST"
        , headers =
            [ Http.header "Accept" "application/json"
            ]
                ++ options.headers
        , url = url
        , body = body
        , expect = expect
        , timeout = options.timeout
        , tracker = options.tracker
        }


handleRequest :
    JD.Decoder data
    -> JD.Decoder answer
    -> RequestId.Id
    -> Http.Response String
    -> Result (Error data) answer
handleRequest dataDecoder answerDecoder id stringResponse =
    case stringResponse of
        Http.BadUrl_ s ->
            Err <| HttpError <| BadUrl s

        Http.Timeout_ ->
            Err <| HttpError Timeout

        Http.NetworkError_ ->
            Err <| HttpError NetworkError

        Http.BadStatus_ metadata body ->
            Err <| HttpError <| BadStatus metadata body

        Http.GoodStatus_ metadata body ->
            if metadata.statusCode == 200 then
                let
                    decoder =
                        Response.decoder dataDecoder answerDecoder
                in
                case JD.decodeString decoder body of
                    Ok response ->
                        let
                            responseId =
                                response.id
                        in
                        case response.result of
                            Ok answer ->
                                let
                                    requestId =
                                        RequestId.toId id
                                in
                                if requestId == responseId then
                                    Ok answer

                                else
                                    Err <|
                                        MismatchedIds
                                            { requestId = requestId
                                            , responseId = responseId
                                            }

                            Err error ->
                                let
                                    errorObject =
                                        ResponseError.toErrorObject error
                                in
                                Err <|
                                    JsonRpcError
                                        { errorObject = errorObject
                                        , responseId = responseId
                                        }

                    Err error ->
                        Err <| DecodeError error

            else
                Err <| UnexpectedStatus metadata body
