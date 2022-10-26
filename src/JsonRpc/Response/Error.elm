module JsonRpc.Response.Error exposing
    ( Error
    , ErrorObject
    , Kind(..)
    , decoder
    , toErrorObject
    )

import Json.Decode as JD


type Error data
    = Error (ErrorObject data)


type alias ErrorObject data =
    { kind : Kind
    , code : Int
    , message : String
    , maybeData : Maybe data
    }


type Kind
    = ParseError
    | InvalidRequest
    | MethodNotFound
    | InvalidParams
    | InternalError
    | ServerError
    | ReservedError
    | ApplicationError


decoder : JD.Decoder data -> JD.Decoder (Error data)
decoder dataDecoder =
    let
        toKind code =
            if code == parseErrorCode then
                ParseError

            else if code == invalidRequestCode then
                InvalidRequest

            else if code == methodNotFoundCode then
                MethodNotFound

            else if code == invalidParamsCode then
                InvalidParams

            else if code == internalErrorCode then
                InternalError

            else if isServerErrorCode code then
                ServerError

            else if isReservedErrorCode code then
                ReservedError

            else
                ApplicationError
    in
    JD.map3
        (\code message maybeData ->
            Error <| ErrorObject (toKind code) code message maybeData
        )
        (JD.field "code" JD.int)
        (JD.field "message" JD.string)
        (JD.maybe <| JD.field "data" dataDecoder)


parseErrorCode : Int
parseErrorCode =
    -32700


invalidRequestCode : Int
invalidRequestCode =
    -32600


methodNotFoundCode : Int
methodNotFoundCode =
    -32601


invalidParamsCode : Int
invalidParamsCode =
    -32602


internalErrorCode : Int
internalErrorCode =
    -32603


isServerErrorCode : Int -> Bool
isServerErrorCode code =
    code >= -32099 && code <= -32000


isReservedErrorCode : Int -> Bool
isReservedErrorCode code =
    code >= -32768 && code <= -32000


toErrorObject : Error data -> ErrorObject data
toErrorObject (Error errorObject) =
    errorObject
