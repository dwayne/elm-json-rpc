module RandomOrg exposing (main)

import Browser
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import JsonRpc
import RandomOrg.Basic.GenerateIntegers as GenerateIntegers


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
    , apiKey : String
    , n : String
    , min : String
    , max : String
    , replacement : String
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( { rpcUrl = "https://api.random.org/json-rpc/4/invoke"
      , apiKey = ""
      , n = "10"
      , min = "1"
      , max = "10"
      , replacement = "true"
      }
    , Cmd.none
    )


type Msg
    = EnteredApiKey String
    | EnteredN String
    | EnteredMin String
    | EnteredMax String
    | EnteredReplacement String
    | ClickedGenerateIntegers
    | GotGenerateIntegersResponse (Result JsonRpc.Error GenerateIntegers.Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EnteredApiKey apiKey ->
            ( { model | apiKey = apiKey }
            , Cmd.none
            )

        EnteredN n ->
            ( { model | n = n }
            , Cmd.none
            )

        EnteredMin min ->
            ( { model | min = min }
            , Cmd.none
            )

        EnteredMax max ->
            ( { model | max = max }
            , Cmd.none
            )

        EnteredReplacement replacement ->
            ( { model | replacement = replacement }
            , Cmd.none
            )

        ClickedGenerateIntegers ->
            ( model
            , let
                maybeParams =
                    Maybe.map3
                        (\n min max ->
                            { n = n
                            , min = min
                            , max = max
                            , maybeReplacement =
                                case model.replacement of
                                    "true" ->
                                        Just True

                                    "false" ->
                                        Just False

                                    _ ->
                                        Nothing
                            }
                        )
                        (String.toInt model.n)
                        (String.toInt model.min)
                        (String.toInt model.max)
              in
              case maybeParams of
                Just params ->
                    JsonRpc.send model.rpcUrl GotGenerateIntegersResponse <|
                        GenerateIntegers.request model.apiKey params

                Nothing ->
                    Cmd.none
            )

        GotGenerateIntegersResponse (Ok response) ->
            ( model
                |> Debug.log (Debug.toString response)
            , Cmd.none
            )

        GotGenerateIntegersResponse (Err e) ->
            ( model
                |> Debug.log (Debug.toString e)
            , Cmd.none
            )


view : Model -> H.Html Msg
view { apiKey, n, min, max, replacement } =
    H.div []
        [ H.h1 [] [ H.text "RandomOrg Examples" ]
        , H.p []
            [ H.label [] [ H.text "API Key: " ]
            , H.input
                [ HA.autofocus True
                , HA.placeholder "Enter your API key"
                , HA.value apiKey
                , HE.onInput EnteredApiKey
                ]
                []
            ]
        , H.p []
            [ H.label [] [ H.text "n: " ]
            , H.input
                [ HA.value n
                , HE.onInput EnteredN
                ]
                []
            ]
        , H.p []
            [ H.label [] [ H.text "min: " ]
            , H.input
                [ HA.value min
                , HE.onInput EnteredMin
                ]
                []
            ]
        , H.p []
            [ H.label [] [ H.text "max: " ]
            , H.input
                [ HA.value max
                , HE.onInput EnteredMax
                ]
                []
            ]
        , H.p []
            [ H.label [] [ H.text "replacement: " ]
            , H.input
                [ HA.value replacement
                , HE.onInput EnteredReplacement
                ]
                []
            ]
        , H.p []
            [ H.button
                [ HE.onClick ClickedGenerateIntegers
                ]
                [ H.text "Generate integers" ]
            ]
        ]
