module Test.JsonRpc.Response exposing (suite)

import Expect exposing (Expectation)
import Json.Decode as JD
import JsonRpc.Id as Id exposing (Id)
import JsonRpc.Response as Response exposing (Response)
import JsonRpc.Response.Error as Error
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "JsonRpc.Response"
        [ decoderSuite
        ]


decoderSuite : Test
decoderSuite =
    describe "decoder"
        [ test "example 1" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "result": 5
                , "id": 1
                }
                """
                    |> expectAnswer
                        { answerDecoder = JD.int
                        , answer = 5
                        , id = Id.int 1
                        }
        , test "example 2" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32700
                    , "message": "Parse error"
                    }
                , "id": null
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ParseError
                            , code = -32700
                            , message = "Parse error"
                            , maybeData = Nothing
                            }
                        , id = Id.null
                        }
        , test "example 3" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32600
                    , "message": "Invalid Request"
                    }
                , "id": null
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.InvalidRequest
                            , code = -32600
                            , message = "Invalid Request"
                            , maybeData = Nothing
                            }
                        , id = Id.null
                        }
        , test "example 4" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32601
                    , "message": "Method not found"
                    }
                , "id": 4
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.MethodNotFound
                            , code = -32601
                            , message = "Method not found"
                            , maybeData = Nothing
                            }
                        , id = Id.int 4
                        }
        , test "example 5" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32602
                    , "message": "Invalid params"
                    }
                , "id": 5
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.InvalidParams
                            , code = -32602
                            , message = "Invalid params"
                            , maybeData = Nothing
                            }
                        , id = Id.int 5
                        }
        , test "example 6" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32603
                    , "message": "Internal error"
                    }
                , "id": 6
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.InternalError
                            , code = -32603
                            , message = "Internal error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 6
                        }
        , test "example 7" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32000
                    , "message": "Server error"
                    }
                , "id": 7
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ServerError
                            , code = -32000
                            , message = "Server error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 7
                        }
        , test "example 8" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32001
                    , "message": "Server error"
                    }
                , "id": 8
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ServerError
                            , code = -32001
                            , message = "Server error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 8
                        }
        , test "example 9" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32098
                    , "message": "Server error"
                    }
                , "id": 9
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ServerError
                            , code = -32098
                            , message = "Server error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 9
                        }
        , test "example 10" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32099
                    , "message": "Server error"
                    }
                , "id": 10
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ServerError
                            , code = -32099
                            , message = "Server error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 10
                        }
        , test "example 11" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32768
                    , "message": "Reserved error"
                    }
                , "id": 11
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ReservedError
                            , code = -32768
                            , message = "Reserved error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 11
                        }
        , test "example 12" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32769
                    , "message": "Application error"
                    }
                , "id": 12
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ApplicationError
                            , code = -32769
                            , message = "Application error"
                            , maybeData = Nothing
                            }
                        , id = Id.int 12
                        }
        , test "example 13" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -31999
                    , "message": "Application error"
                    }
                , "id": "thirteen"
                }
                """
                    |> expectError
                        { dataDecoder = unitDecoder
                        , errorObject =
                            { kind = Error.ApplicationError
                            , code = -31999
                            , message = "Application error"
                            , maybeData = Nothing
                            }
                        , id = Id.string "thirteen"
                        }
        , test "example 14" <|
            \_ ->
                """
                { "jsonrpc": "2.0"
                , "error":
                    { "code": -32700
                    , "message": "Parse error"
                    , "data": "missing closing parenthesis"
                    }
                , "id": null
                }
                """
                    |> expectError
                        { dataDecoder = JD.string
                        , errorObject =
                            { kind = Error.ParseError
                            , code = -32700
                            , message = "Parse error"
                            , maybeData = Just "missing closing parenthesis"
                            }
                        , id = Id.null
                        }
        , test "example 15" <|
            \_ ->
                let
                    rawJsonResponse =
                        """
                        { "jsonrpc": "2.0"
                        , "result": 5
                        , "error":
                            { "code": -32700
                            , "message": "Parse error"
                            }
                        }
                        """

                    decoder =
                        Response.decoder unitDecoder unitDecoder

                    expectedMessage =
                        "both result and error MUST NOT be included"
                in
                case JD.decodeString decoder rawJsonResponse of
                    Err (JD.Failure message _) ->
                        Expect.equal expectedMessage message

                    _ ->
                        Expect.fail expectedMessage
        , test "example 16" <|
            \_ ->
                let
                    rawJsonResponse =
                        """
                        { "jsonrpc": "2.0"
                        }
                        """

                    decoder =
                        Response.decoder unitDecoder unitDecoder

                    expectedMessage =
                        "either the result or error MUST be included"
                in
                case JD.decodeString decoder rawJsonResponse of
                    Err (JD.Failure message _) ->
                        Expect.equal expectedMessage message

                    _ ->
                        Expect.fail expectedMessage
        , test "example 17" <|
            \_ ->
                let
                    rawJsonResponse =
                        """
                        { "jsonrpc": "2"
                        }
                        """

                    decoder =
                        Response.decoder unitDecoder unitDecoder

                    expectedMessage =
                        "jsonrpc MUST be exactly \"2.0\""
                in
                case JD.decodeString decoder rawJsonResponse of
                    Err (JD.Failure message _) ->
                        Expect.equal expectedMessage message

                    _ ->
                        Expect.fail expectedMessage
        , test "example 18" <|
            \_ ->
                let
                    rawJsonResponse =
                        """
                        { "jsonrpc": "2.0"
                        , "result": 1
                        , "id": 18.5
                        }
                        """

                    decoder =
                        Response.decoder unitDecoder unitDecoder

                    expectedMessage =
                        "expected a String, Int, or null"
                in
                case JD.decodeString decoder rawJsonResponse of
                    Err error ->
                        JD.errorToString error
                            |> expectMatch "id failed"

                    _ ->
                        Expect.fail expectedMessage
        ]


expectAnswer :
    { answerDecoder : JD.Decoder answer
    , answer : answer
    , id : Id
    }
    -> String
    -> Expectation
expectAnswer { answerDecoder, answer, id } rawJsonResponse =
    let
        decoder =
            Response.decoder unitDecoder answerDecoder

        expectedResponse =
            { result = Ok answer
            , id = id
            }
    in
    JD.decodeString decoder rawJsonResponse
        |> Expect.equal (Ok expectedResponse)


expectError :
    { dataDecoder : JD.Decoder data
    , errorObject : Error.ErrorObject data
    , id : Id
    }
    -> String
    -> Expectation
expectError { dataDecoder, errorObject, id } rawJsonResponse =
    let
        decoder =
            Response.decoder dataDecoder unitDecoder
    in
    case JD.decodeString decoder rawJsonResponse of
        Ok response ->
            let
                newResponse =
                    { result = Result.mapError Error.toErrorObject response.result
                    , id = response.id
                    }
            in
            Expect.all
                [ .result >> Expect.equal (Err errorObject)
                , .id >> Expect.equal id
                ]
                newResponse

        Err error ->
            Expect.fail <| JD.errorToString error


expectMatch : String -> String -> Expectation
expectMatch substring source =
    if String.contains substring source then
        Expect.pass

    else
        Expect.fail <| "The source string:\n\n" ++ source ++ "\n\ndoes not contain the substring:\n\n" ++ substring


unitDecoder : JD.Decoder ()
unitDecoder =
    JD.succeed ()
