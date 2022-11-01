module Ethereum.Eth.ChainId exposing (request)

import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Params as Params
import JsonRpc.Transport.Http exposing (Request)


request : Request JE.Value String
request =
    { method = "eth_chainId"
    , params = Params.empty
    , dataDecoder = JD.value
    , answerDecoder = JD.string
    }
