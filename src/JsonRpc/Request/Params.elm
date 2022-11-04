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


byName : ( String, Param ) -> List ( String, Param ) -> Params
byName first rest =
    Object <| first :: rest


toJson : Params -> JE.Value
toJson params =
    case params of
        Array positionalParams ->
            JE.list identity positionalParams

        Object namedParams ->
            JE.object namedParams
