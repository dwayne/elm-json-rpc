module JsonRpc.Version exposing (toJson, version)

import Json.Encode as JE


version : String
version =
    "2.0"


toJson : JE.Value
toJson =
    JE.string version
