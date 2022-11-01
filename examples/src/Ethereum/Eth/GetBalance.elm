module Ethereum.Eth.GetBalance exposing (request)

import Ethereum.Data.Address as Address exposing (Address)
import Ethereum.Data.Block as Block exposing (Block)
import Json.Decode as JD
import Json.Encode as JE
import JsonRpc.Request.Params as Params
import JsonRpc.Transport.Http exposing (Request)


type alias Options =
    { address : Address

    -- FIXME:
    --
    -- The spec says that this parameter is optional yet when I don't send it
    -- along the response is an error.
    , maybeBlock : Maybe Block
    }


request : Options -> Request JE.Value String
request { address, maybeBlock } =
    { method = "eth_getBalance"
    , params =
        [ Just <| Address.encode address
        , Maybe.map Block.encode maybeBlock
        ]
            |> List.filterMap identity
            |> Params.byPosition
    , dataDecoder = JD.value
    , answerDecoder = JD.string
    }
