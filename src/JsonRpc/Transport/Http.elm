module JsonRpc.Transport.Http exposing
    ( Error(..)
    , HttpError(..)
    , Options
    , Request
    , send
    )

import Http
import Json.Decode as JD
import JsonRpc.Request as Request
import JsonRpc.Request.Id as RequestId
import JsonRpc.Request.Params exposing (Params)
import JsonRpc.Response as Response
import JsonRpc.Response.Error as ResponseError
import JsonRpc.Response.Id as ResponseId


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
        { requestId : String
        , responseId : String
        }
    | JsonRpcError
        { kind : ResponseError.Kind
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


type alias Options data answer msg =
    { url : String
    , toMsg : Result (Error data) answer -> msg
    , headers : List Http.Header
    , timeout : Maybe Float
    , tracker : Maybe String
    }


send : Options data answer msg -> Request data answer -> Cmd msg
send options { method, params, dataDecoder, answerDecoder } =
    let
        id =
            RequestId.int 1

        body =
            Request.request method params id
                |> Request.toJson
                |> Http.jsonBody

        expect =
            handleRequest dataDecoder answerDecoder id
                |> Http.expectStringResponse options.toMsg
    in
    Http.request
        { method = "POST"
        , headers =
            [ Http.header "Accept" "application/json"
            ]
                ++ options.headers
        , url = options.url
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
                                ResponseId.toString response.id
                        in
                        case response.result of
                            Ok answer ->
                                let
                                    requestId =
                                        RequestId.toString id
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
                                    { kind, code, message, maybeData } =
                                        ResponseError.toErrorObject error
                                in
                                Err <|
                                    JsonRpcError
                                        { kind = kind
                                        , code = code
                                        , message = message
                                        , maybeData = maybeData
                                        , responseId = responseId
                                        }

                    Err error ->
                        Err <| DecodeError error

            else
                Err <| UnexpectedStatus metadata body
