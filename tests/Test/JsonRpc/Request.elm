module Test.JsonRpc.Request exposing (suite)

import Expect exposing (Expectation)
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request as Request exposing (Request)
import JsonRpc.Request.Id as Id
import JsonRpc.Request.Params as Params
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "JsonRpc.Request"
        [ requestSuite
        ]


requestSuite : Test
requestSuite =
    describe "request"
        [ test "example 1" <|
            \_ ->
                let
                    request =
                        Request.request "currentTime" Nothing (Id.int 1)
                in
                request
                    |> expectRequestObject
                        { method = "currentTime"
                        , maybeParams = Nothing
                        , id = 1
                        }
        , test "example 2" <|
            \_ ->
                let
                    request =
                        Request.request "negate" (Just params) (Id.int 2)

                    params =
                        Params.byPosition (JE.int 1) []
                in
                request
                    |> expectRequestObject
                        { method = "negate"
                        , maybeParams = Just [ 1 ]
                        , id = 2
                        }
        , test "example 3" <|
            \_ ->
                let
                    request =
                        Request.request "subtract" (Just params) (Id.int 3)

                    params =
                        Params.byPosition (JE.int 10) [ JE.int 2 ]
                in
                request
                    |> expectRequestObject
                        { method = "subtract"
                        , maybeParams = Just [ 10, 2 ]
                        , id = 3
                        }
        ]


type alias RequestObject =
    { method : String
    , maybeParams : Maybe (List Int)
    , id : Int
    }


requestObjectDecoder : JD.Decoder RequestObject
requestObjectDecoder =
    JD.field "jsonrpc" JD.string
        |> JD.andThen
            (\s ->
                if s == "2.0" then
                    JD.map3 RequestObject
                        (JD.field "method" JD.string)
                        (JD.maybe <| JD.field "params" <| JD.list JD.int)
                        (JD.field "id" JD.int)

                else
                    JD.fail "jsonrpc MUST be exactly \"2.0\""
            )


expectRequestObject : RequestObject -> Request -> Expectation
expectRequestObject { method, maybeParams, id } request =
    let
        result =
            request
                |> Request.encode
                |> JD.decodeValue requestObjectDecoder
    in
    case result of
        Ok requestObject ->
            Expect.all
                [ .method >> Expect.equal method
                , .maybeParams >> Expect.equal maybeParams
                , .id >> Expect.equal id
                ]
                requestObject

        Err error ->
            Expect.fail <| JD.errorToString error
