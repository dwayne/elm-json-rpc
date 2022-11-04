module Ethereum.Eth.ChainId exposing (request)

import Json.Decode as JD
import JsonRpc


request : JsonRpc.Request String
request =
    { method = "eth_chainId"
    , params = JsonRpc.empty
    , result = JD.string
    }
