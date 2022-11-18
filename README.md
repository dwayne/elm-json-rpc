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

A JSON-RPC request can fail in many ways. Suppose the `currentTime` RPC call
fails then in our update function we can handle it as follows:

```elm
import JsonRpc

GotCurrentTime (Err error) ->
  case error of
      JsonRpc.HttpError httpError ->
          -- There was an error trying to
          -- reach the server.
          ...

      JsonRpc.UnexpectedStatus metadata body ->
          -- A successful HTTP status code
          -- other than 200 was returned.
          ...

      JsonRpc.DecodeError jsonDecodeError ->
          -- The Response object returned
          -- by the server was malformed.
          ...

      JsonRpc.MismatchedIds { requestId, responseId } ->
          -- The id of the Request object
          -- is not the same as the id of
          -- the Response object.
          ...

      JsonRpc.JsonRpcError { kind, code, message, maybeData, responseId } ->
          -- The RPC call encountered an error.
          -- The maybeData field may contain
          -- detailed error information as
          -- defined by the server.
          ...
```

## Examples

The `examples` directory contains:

- An [Ethereum](https://ethereum.github.io/execution-apis/api-documentation/)
example based on `eth_chainId` and `eth_getBalance`.
- A [RandomOrg](https://api.random.org/json-rpc/4/basic) example based on
`generateIntegers`.

To play with the examples do the following:

```bash
$ nix-shell
$ serve-examples
```

Then, open http://localhost:8000 in your browser and explore!
