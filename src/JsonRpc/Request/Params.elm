module JsonRpc.Request.Params exposing
    ( Param
    , Params
    , byName
    , byPosition
    , empty
    , toJson
    )

import Json.Encode as JE


type Params
    = Array (List Param)
    | Object (List ( String, Param ))


type alias Param =
    JE.Value


empty : Params
empty =
    Array []


byPosition : List Param -> Params
byPosition =
    Array


byName : List ( String, Param ) -> List ( String, Maybe Param ) -> Params
byName required maybeParams =
    let
        optional =
            List.filterMap
                (\( key, maybeParam ) ->
                    case maybeParam of
                        Just param ->
                            Just ( key, param )

                        Nothing ->
                            Nothing
                )
                maybeParams

        kwParams =
            required ++ optional
    in
    case kwParams of
        [] ->
            empty

        _ ->
            Object kwParams


toJson : Params -> JE.Value
toJson params =
    case params of
        Array positionalParams ->
            JE.list identity positionalParams

        Object namedParams ->
            JE.object namedParams
