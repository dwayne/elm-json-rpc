module Ethereum.Data.Block exposing
    ( Block
    , Tag(..)
    , encode
    , fromNumber
    , fromTag
    )

import Ethereum.Lib.Parser as P
import Json.Encode as JE
import Parser as P exposing ((|.), (|=), Parser)


type Block
    = Number String
    | Tag Tag


type Tag
    = Earliest
    | Finalized
    | Safe
    | Latest
    | Pending


fromNumber : String -> Maybe Block
fromNumber s =
    case P.run numberParser s of
        Ok number ->
            Just <| Number number

        Err _ ->
            Nothing


numberParser : Parser String
numberParser =
    -- ^0x([1-9a-f]+[0-9a-f]*|0)$
    let
        isHexDigit c =
            "0123456789abcdef"
                |> String.toList
                |> List.member c

        isNonZeroHexDigit c =
            isHexDigit c && c /= '0'

        nonZero =
            P.getChompedString <|
                P.succeed ()
                    |. P.chompIf isNonZeroHexDigit
                    |. P.chompWhile isHexDigit

        zero =
            P.string "0"
    in
    P.succeed (++)
        |= P.string "0x"
        |= P.oneOf [ nonZero, zero ]
        |. P.end


fromTag : Tag -> Block
fromTag =
    Tag


encode : Block -> JE.Value
encode block =
    case block of
        Number number ->
            JE.string number

        Tag tag ->
            JE.string <|
                case tag of
                    Earliest ->
                        "earliest"

                    Finalized ->
                        "finalized"

                    Safe ->
                        "safe"

                    Latest ->
                        "latest"

                    Pending ->
                        "pending"
