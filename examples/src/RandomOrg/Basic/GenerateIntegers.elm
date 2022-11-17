module RandomOrg.Basic.GenerateIntegers exposing
    ( Params
    , Random
    , Response
    , request
    )

import Json.Decode as JD
import Json.Encode as JE
import JsonRpc


type alias Params =
    { n : Int
    , min : Int
    , max : Int
    , maybeReplacement : Maybe Bool
    }


type alias Response =
    { random : Random
    , bitsUsed : Int
    , bitsLeft : Int
    , requestsLeft : Int
    , advisoryDelay : Int
    }


type alias Random =
    { data : List Int
    , completionTime : String
    }


request : String -> Params -> JsonRpc.Request Response
request apiKey params =
    { method = "generateIntegers"
    , params =
        JsonRpc.namedParams
            [ ( "apiKey", JE.string apiKey )
            , ( "n", JE.int params.n )
            , ( "min", JE.int params.min )
            , ( "max", JE.int params.max )
            ]
            [ ( "replacement", Maybe.map JE.bool params.maybeReplacement )
            ]
    , result = responseDecoder
    }


responseDecoder : JD.Decoder Response
responseDecoder =
    JD.map5 Response
        (JD.field "random" randomDecoder)
        (JD.field "bitsUsed" JD.int)
        (JD.field "bitsLeft" JD.int)
        (JD.field "requestsLeft" JD.int)
        (JD.field "advisoryDelay" JD.int)


randomDecoder : JD.Decoder Random
randomDecoder =
    JD.map2 Random
        (JD.field "data" <| JD.list JD.int)
        (JD.field "completionTime" JD.string)
