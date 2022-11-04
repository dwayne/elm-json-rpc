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
                        Request.request "currentTime" Params.empty (Id.int 1)
                in
                request
                    |> expectRequestObject
                        { method = "currentTime"
                        , params = []
                        , maybeId = Just 1
                        }
        , test "example 2" <|
            \_ ->
                let
                    request =
                        Request.request "negate" params (Id.int 2)

                    params =
                        Params.byPosition [ JE.int 1 ]
                in
                request
                    |> expectRequestObject
                        { method = "negate"
                        , params = [ 1 ]
                        , maybeId = Just 2
                        }
        , test "example 3" <|
            \_ ->
                let
                    request =
                        Request.request "subtract" params (Id.int 3)

                    params =
                        Params.byPosition [ JE.int 10, JE.int 2 ]
                in
                request
                    |> expectRequestObject
                        { method = "subtract"
                        , params = [ 10, 2 ]
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
                        Request.notification "foobar" Params.empty
                in
                notification
                    |> expectRequestObject
                        { method = "foobar"
                        , params = []
                        , maybeId = Nothing
                        }
        , test "example 2" <|
            \_ ->
                let
                    notification =
                        Request.notification "update" params

                    params =
                        Params.byPosition
                            [ JE.int 1
                            , JE.int 2
                            , JE.int 3
                            , JE.int 4
                            , JE.int 5
                            ]
                in
                notification
                    |> expectRequestObject
                        { method = "update"
                        , params = [ 1, 2, 3, 4, 5 ]
                        , maybeId = Nothing
                        }
        ]


type alias RequestObject =
    { method : String
    , params : List Int
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
                        (JD.field "params" <| JD.list JD.int)
                        (JD.maybe <| JD.field "id" JD.int)

                else
                    JD.fail "jsonrpc MUST be exactly \"2.0\""
            )


expectRequestObject : RequestObject -> Request -> Expectation
expectRequestObject { method, params, maybeId } request =
    let
        result =
            request
                |> Request.toJson
                |> JD.decodeValue requestObjectDecoder
    in
    case result of
        Ok requestObject ->
            Expect.all
                [ .method >> Expect.equal method
                , .params >> Expect.equal params
                , .maybeId >> Expect.equal maybeId
                ]
                requestObject

        Err error ->
            Expect.fail <| JD.errorToString error
