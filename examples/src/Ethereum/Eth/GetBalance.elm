module Ethereum.Eth.GetBalance exposing (Options, request)

import Ethereum.Data.Address as Address exposing (Address)
import Ethereum.Data.Block as Block exposing (Block)
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Params as Params
import JsonRpc.Transport.Http exposing (Request)


type alias Options =
    { address : Address
    , block : Block
    }


request : Options -> Request JE.Value String
request { address, block } =
    { method = "eth_getBalance"
    , params =
        Params.byPosition
            [ Address.encode address
            , Block.encode block
            ]
    , dataDecoder = JD.value
    , answerDecoder = JD.string
    }
