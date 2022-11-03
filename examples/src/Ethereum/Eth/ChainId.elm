module Ethereum.Eth.ChainId exposing (request)

import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Advanced as JsonRpc


request : JsonRpc.Request JE.Value String
request =
    { method = "eth_chainId"
    , params = JsonRpc.emptyParams
    , dataDecoder = JD.value
    , answerDecoder = JD.string
    }
