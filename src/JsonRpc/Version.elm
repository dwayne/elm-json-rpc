module JsonRpc.Version exposing (encode, version)

import Json.Encode as JE


version : String
version =
    "2.0"


encode : JE.Value
encode =
    JE.string version
