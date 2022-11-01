module Ethereum.Lib.Parser exposing (exactly, string)

import Parser as P exposing (Parser)


string : String -> Parser String
string =
    P.getChompedString << stringHelper


stringHelper : String -> Parser ()
stringHelper s =
    case String.uncons s of
        Nothing ->
            P.succeed ()

        Just ( c, t ) ->
            P.chompIf ((==) c)
                |> P.andThen (\_ -> stringHelper t)


exactly : Int -> (Char -> Bool) -> Parser String
exactly n pred =
    pred
        |> P.chompIf
        |> exactlyHelper n
        |> P.loop 0
        |> P.getChompedString


exactlyHelper : Int -> Parser () -> Int -> Parser (P.Step Int ())
exactlyHelper n p i =
    if i < n then
        p |> P.andThen (\_ -> P.succeed <| P.Loop <| i + 1)

    else
        P.succeed <| P.Done ()
