module JsonRpc.Response exposing (Response, decoder)


import Json.Decode as JD
import JsonRpc.Response.Error as Error exposing (Error)
import JsonRpc.Response.Id as Id exposing (Id)
import JsonRpc.Version as Version


type alias Response data answer =
    { outcome : Result (Error data) answer
    , id : Id
    }


decoder : JD.Decoder data -> JD.Decoder answer -> JD.Decoder (Response data answer)
decoder dataDecoder answerDecoder =
    JD.field "jsonrpc" JD.string
        |> JD.andThen
            (\s ->
                if s == Version.version then
                    JD.map2 Response
                        (outcomeDecoder dataDecoder answerDecoder)
                        (JD.field "id" Id.decoder)
                else
                    JD.fail <| "jsonrpc MUST be exactly \"" ++ Version.version ++ "\""
            )


outcomeDecoder : JD.Decoder data -> JD.Decoder answer -> JD.Decoder (Result (Error data) answer)
outcomeDecoder dataDecoder answerDecoder =
    JD.field "result" (JD.succeed True)
        |> JD.andThen
            (\hasResult ->
                JD.field "error" (JD.succeed True)
                    |> JD.andThen
                        (\hasError ->
                            case (hasResult, hasError) of
                                (True, False) ->
                                    JD.map Ok
                                        (JD.field "result" answerDecoder)

                                (False, True) ->
                                    JD.map Err
                                        (JD.field "error" <| Error.decoder dataDecoder)

                                (True, True) ->
                                    JD.fail "both result and error MUST NOT be included"

                                (False, False) ->
                                    JD.fail "either the result or error MUST be included"
                        )
            )
