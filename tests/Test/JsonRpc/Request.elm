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
        , notificationSuite
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
                        , maybeId = Just 1
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
                        , maybeId = Just 2
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
                        , maybeId = Just 3
                        }
        ]


notificationSuite : Test
notificationSuite =
    describe "notification"
        [ test "example 1" <|
            \_ ->
                let
                    notification =
                        Request.notification "foobar" Nothing
                in
                notification
                    |> expectRequestObject
                        { method = "foobar"
                        , maybeParams = Nothing
                        , maybeId = Nothing
                        }
        , test "example 2" <|
            \_ ->
                let
                    notification =
                        Request.notification "update" (Just params)

                    params =
                        Params.byPosition (JE.int 1)
                            [ JE.int 2
                            , JE.int 3
                            , JE.int 4
                            , JE.int 5
                            ]
                in
                notification
                    |> expectRequestObject
                        { method = "update"
                        , maybeParams = Just [ 1, 2, 3, 4, 5 ]
                        , maybeId = Nothing
                        }
        ]


type alias RequestObject =
    { method : String
    , maybeParams : Maybe (List Int)
    , maybeId : Maybe Int
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
                        (JD.maybe <| JD.field "id" JD.int)

                else
                    JD.fail "jsonrpc MUST be exactly \"2.0\""
            )


expectRequestObject : RequestObject -> Request -> Expectation
expectRequestObject { method, maybeParams, maybeId } request =
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
                , .maybeId >> Expect.equal maybeId
                ]
                requestObject

        Err error ->
            Expect.fail <| JD.errorToString error
