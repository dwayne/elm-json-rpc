module Ethereum exposing (main)

import Browser
import Ethereum.Data.Address as Address
import Ethereum.Data.Block as Block
import Ethereum.Eth.ChainId as EthChainId
import Ethereum.Eth.GetBalance as EthGetBalance
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import JsonRpc


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type alias Model =
    { rpcUrl : String
    , address : String
    , block : String
    , maybeChainId : Maybe String
    , maybeBalance : Maybe String
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( { rpcUrl = "https://eth-goerli.public.blastapi.io"
      , address = "0x0000000000000000000000000000000000000000"
      , block = "latest"
      , maybeChainId = Nothing
      , maybeBalance = Nothing
      }
    , Cmd.none
    )


type Msg
    = EnteredRpcUrl String
    | EnteredAddress String
    | EnteredBlock String
    | ClickedGetChainId
    | GotChainId (Result JsonRpc.Error String)
    | ClickedGetBalance
    | GotBalance (Result JsonRpc.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EnteredRpcUrl rpcUrl ->
            ( { model | rpcUrl = rpcUrl }
            , Cmd.none
            )

        EnteredAddress address ->
            ( { model | address = address }
            , Cmd.none
            )

        EnteredBlock block ->
            ( { model | block = block }
            , Cmd.none
            )

        ClickedGetChainId ->
            ( model
            , JsonRpc.send model.rpcUrl GotChainId EthChainId.request
            )

        GotChainId (Ok chainId) ->
            ( { model | maybeChainId = Just chainId }
            , Cmd.none
            )

        GotChainId (Err e) ->
            ( model
                |> Debug.log (Debug.toString e)
            , Cmd.none
            )

        ClickedGetBalance ->
            ( model
            , let
                sendEthGetBalance address block =
                    JsonRpc.sendWithId
                        model.rpcUrl
                        GotBalance
                        (JsonRpc.stringId "0x1ae4f")
                    <|
                        EthGetBalance.request
                            { address = address
                            , block = block
                            }
              in
              Maybe.map2 sendEthGetBalance
                (Address.fromString model.address)
                (Block.fromString model.block)
                |> Maybe.withDefault Cmd.none
            )

        GotBalance (Ok balance) ->
            ( { model | maybeBalance = Just balance }
            , Cmd.none
            )

        GotBalance (Err e) ->
            ( model
                |> Debug.log (Debug.toString e)
            , Cmd.none
            )


view : Model -> H.Html Msg
view { rpcUrl, address, block, maybeChainId, maybeBalance } =
    H.div []
        [ H.h1 [] [ H.text "Ethereum Examples" ]
        , H.p []
            [ H.label [] [ H.text "JSON-RPC server URL: " ]
            , H.input
                [ HA.autofocus True
                , HA.placeholder "Enter a URL"
                , HA.value rpcUrl
                , HE.onInput EnteredRpcUrl
                ]
                []
            ]
        , H.h2 [] [ H.text "eth_chainId" ]
        , case maybeChainId of
            Nothing ->
                H.p [] [ H.text "Click the button below to get the chainId." ]

            Just chainId ->
                H.p []
                    [ H.text "The chainId is "
                    , H.text chainId
                    , H.text "."
                    ]
        , H.p []
            [ H.button
                [ HE.onClick ClickedGetChainId
                ]
                [ H.text "Get chainId" ]
            ]
        , H.h2 [] [ H.text "eth_getBalance" ]
        , H.p []
            [ H.label [] [ H.text "Address: " ]
            , H.input
                [ HA.placeholder "Enter an address"
                , HA.value address
                , HE.onInput EnteredAddress
                ]
                []
            ]
        , H.p []
            [ H.label [] [ H.text "Block: " ]
            , H.input
                [ HA.placeholder "Enter a block number or tag"
                , HA.value block
                , HE.onInput EnteredBlock
                ]
                []
            ]
        , case maybeBalance of
            Nothing ->
                H.p [] [ H.text "Click the button below to get the balance." ]

            Just balance ->
                H.p []
                    [ H.text "The balance is "
                    , H.text balance
                    , H.text "."
                    ]
        , H.p []
            [ H.button
                [ HE.onClick ClickedGetBalance
                ]
                [ H.text "Get balance" ]
            ]
        ]
