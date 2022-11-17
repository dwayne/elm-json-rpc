# Elm JSON-RPC

A [JSON-RPC 2.0](https://www.jsonrpc.org/specification) library for Elm. You can
use it to send
[JSON-RPC requests](https://www.jsonrpc.org/specification#request_object)
over HTTP.

## Creating requests

A request with no parameters:

```elm
import Json.Decode as JD
import JsonRpc

currentTime : JsonRpc.Request String
currentTime =
    { method = "currentTime"
    , params = JsonRpc.noParams
    , result = JD.string
    }
```

A request with positional parameters:

```elm
import Json.Encode as JE

add : Int -> Int -> JsonRpc.Request Int
add a b =
    { method = "add"
    , params =
        JsonRpc.positionalParams
            [ JE.int a
            , JE.int b
            ]
    , result = JD.int
    }
```

A request with named parameters:

```elm
subtract : Float -> Float -> JsonRpc.Request Float
subtract minuend subtrahend =
    { method = "subtract"
    , params =
        JsonRpc.namedParams
            [ ( "minuend", JE.float minuend )
            , ( "subtrahend", JE.float subtrahend )
            ]
            -- No optional parameters
            []
    , result = JD.float
    }

intToString : Int -> Maybe Int -> JsonRpc.Request String
intToString n maybeBase =
    { method = "intToString"
    , params =
        JsonRpc.namedParams
            [ ( "n", JE.float minuend )
            ]
            -- 1 optional parameter
            --
            -- If maybeBase is Nothing then
            -- the named parameter "base"
            -- isn't sent over the wire
            [ ( "base", Maybe.map JE.int maybeBase )
            ]
    , result = JD.string
    }
```

## Sending requests

### Basics

```elm
rpcUrl = "https://json-rpc.example.com"

type Msg
    = GotCurrentTime (Result JsonRpc.Error String)

JsonRpc.send rpcUrl GotCurrentTime currentTime
```

This will send the JSON-RPC request:

```json
{
    "jsonrpc": "2.0",
    "method": "currentTime",
    "params": [],
    "id": 1
}
```

over HTTP to the endpoint `https://json-rpc.example.com`.

### Changing the request identifier

To change the request identifier use `sendWithId`.

Use an integer identifier:

```elm
JsonRpc.sendWithId
    rpcUrl
    GotCurrentTime
    (JsonRpc.intId 2)
    currentTime
```

The corresponding JSON-RPC request will be:

```json
{
    "jsonrpc": "2.0",
    "method": "currentTime",
    "params": [],
    "id": 2
}
```

Use a string identifier:

```elm
JsonRpc.sendWithId
    rpcUrl
    GotCurrentTime
    (JsonRpc.stringId "abc123")
    currentTime
```

The corresponding JSON-RPC request will be:

```json
{
    "jsonrpc": "2.0",
    "method": "currentTime",
    "params": [],
    "id": "abc123"
}
```

### Want to change the HTTP settings?

Take a look at `sendCustom`.

## Handling errors

TODO

## More examples

TODO
