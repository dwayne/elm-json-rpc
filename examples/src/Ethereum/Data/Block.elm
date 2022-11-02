module Ethereum.Data.Block exposing
    ( Block
    , Tag(..)
    , encode
    , fromString
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


fromString : String -> Maybe Block
fromString s =
    case s of
        "earliest" ->
            Just <| Tag Earliest

        "finalized" ->
            Just <| Tag Finalized

        "safe" ->
            Just <| Tag Safe

        "latest" ->
            Just <| Tag Latest

        "pending" ->
            Just <| Tag Pending

        _ ->
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
