module Ethereum.Eth.GetBalance exposing (Options, request)

import Ethereum.Data.Address as Address exposing (Address)
import Ethereum.Data.Block as Block exposing (Block)
import Json.Decode as JD
import JsonRpc


type alias Options =
    { address : Address
    , block : Block
    }


request : Options -> JsonRpc.Request String
request { address, block } =
    { method = "eth_getBalance"
    , params =
        JsonRpc.positionalParams
            [ Address.encode address
            , Block.encode block
            ]
    , result = JD.string
    }
