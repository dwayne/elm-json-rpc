module Example1 exposing (main)

import Browser
import Ethereum.Data.Address as Address
import Ethereum.Data.Block as Block
import Ethereum.Eth.ChainId as EthChainId
import Ethereum.Eth.GetBalance as EthGetBalance
import Html as H
import Html.Events as HE
import Json.Encode as JE
import JsonRpc.Transport.Http as JsonRpcHttp


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


url : String
url =
    "https://rpc.flashbots.net/"


type alias Model =
    { maybeChainId : Maybe String
    , maybeBalance : Maybe String
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( { maybeChainId = Nothing
      , maybeBalance = Nothing
      }
    , Cmd.none
    )


type Msg
    = ClickedGetChainId
    | GotChainId (Result (JsonRpcHttp.Error JE.Value) String)
    | ClickedGetBalance
    | GotBalance (Result (JsonRpcHttp.Error JE.Value) String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedGetChainId ->
            ( model
            , JsonRpcHttp.sendDefault url GotChainId EthChainId.request
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
            , JsonRpcHttp.sendDefault url GotBalance <|
                EthGetBalance.request
                    { address = Address.genesis
                    , maybeBlock = Just <| Block.fromTag Block.Finalized
                    }
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
view { maybeChainId, maybeBalance } =
    H.div []
        [ H.h1 [] [ H.text "Examples" ]
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
