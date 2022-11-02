module Ethereum.Data.Address exposing
    ( Address
    , encode
    , fromString
    )

import Ethereum.Lib.Parser as P
import Json.Encode as JE
import Parser as P exposing ((|.), (|=), Parser)


type Address
    = Address String


fromString : String -> Maybe Address
fromString s =
    case P.run addressParser s of
        Ok address ->
            Just <| Address address

        Err _ ->
            Nothing


addressParser : Parser String
addressParser =
    -- ^0x[0-9a-fA-F]{40}$
    P.succeed (++)
        |= P.string "0x"
        |= P.exactly 40 Char.isHexDigit
        |. P.end


encode : Address -> JE.Value
encode (Address address) =
    JE.string address
