module JsonRpc.Response exposing (Response, decoder)

import Json.Decode as JD
import JsonRpc.Response.Error as Error exposing (Error)
import JsonRpc.Response.Id as Id exposing (Id)
import JsonRpc.Version as Version


type alias Response data answer =
    { result : Result (Error data) answer
    , id : Id
    }


decoder : JD.Decoder data -> JD.Decoder answer -> JD.Decoder (Response data answer)
decoder dataDecoder answerDecoder =
    JD.field "jsonrpc" JD.string
        |> JD.andThen
            (\s ->
                if s == Version.version then
                    JD.map2 Response
                        (resultDecoder dataDecoder answerDecoder)
                        (JD.field "id" Id.decoder)

                else
                    JD.fail <| "jsonrpc MUST be exactly \"" ++ Version.version ++ "\""
            )


resultDecoder : JD.Decoder data -> JD.Decoder answer -> JD.Decoder (Result (Error data) answer)
resultDecoder dataDecoder answerDecoder =
    JD.maybe (JD.field "result" (JD.succeed ()))
        |> JD.andThen
            (\maybeResult ->
                JD.maybe (JD.field "error" (JD.succeed ()))
                    |> JD.andThen
                        (\maybeError ->
                            case ( maybeResult, maybeError ) of
                                ( Just (), Nothing ) ->
                                    JD.map Ok
                                        (JD.field "result" answerDecoder)

                                ( Nothing, Just () ) ->
                                    JD.map Err
                                        (JD.field "error" <| Error.decoder dataDecoder)

                                ( Just (), Just () ) ->
                                    JD.fail "both result and error MUST NOT be included"

                                ( Nothing, Nothing ) ->
                                    JD.fail "either the result or error MUST be included"
                        )
            )
