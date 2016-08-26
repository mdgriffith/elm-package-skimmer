port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App
import Time exposing (Time, second)
import String


main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { retrieved : String
    , packages : List Package
    , query : String
    }


type alias Package =
    { name : String
    , deprecated : Bool
    , summary : String
    , is_current : Bool
    , stars : Int
    , forks : Int
    , watchers : Int
    , open_issues : Int
    , has_tests : Bool
    , has_examples : Bool
    , versions : List String
    , license : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    ( { retrieved = "Never", packages = [], query = "" }, Cmd.none )


type Msg
    = Load
        { retrieved : String
        , packages : List Package
        }
    | Query String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Query query ->
            ( { model | query = query }
            , Cmd.none
            )

        Load packages ->
            let
                sortedPkgs =
                    List.sortWith
                        (\pkg1 pkg2 ->
                            let
                                boolAsInt b1 =
                                    if b1 then
                                        1
                                    else
                                        0

                                dep =
                                    compare
                                        (boolAsInt <| not pkg2.deprecated)
                                        (boolAsInt <| not pkg1.deprecated)

                                current =
                                    compare
                                        (boolAsInt pkg2.is_current)
                                        (boolAsInt pkg1.is_current)

                                stars =
                                    compare pkg2.stars pkg1.stars
                            in
                                case dep of
                                    EQ ->
                                        case current of
                                            EQ ->
                                                stars

                                            _ ->
                                                current

                                    _ ->
                                        dep
                        )
                        packages.packages
            in
                ( { model
                    | packages = sortedPkgs
                    , retrieved = packages.retrieved
                  }
                , Cmd.none
                )


port packages :
    ({ retrieved : String
     , packages : List Package
     }
     -> msg
    )
    -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    packages Load


searchFor : String -> List Package -> List Package
searchFor query packages =
    if query == "" then
        packages
    else
        let
            queryTerms =
                String.words (String.toLower query)

            matchesQueryTerms pkg =
                let
                    lowerName =
                        String.toLower pkg.name

                    lowerSummary =
                        String.toLower pkg.summary

                    findTerm term =
                        String.contains term lowerName
                            || String.contains term lowerSummary
                in
                    List.all findTerm queryTerms
        in
            List.filter matchesQueryTerms packages


view : Model -> Html Msg
view model =
    div []
        [ viewToolbar model.retrieved model.query
          --, div [] [viewSidebar]
        , viewPackages (searchFor model.query model.packages)
        ]


viewToolbar : String -> String -> Html Msg
viewToolbar refreshed query =
    div [ class "toolbar" ]
        [ span [ class "logo" ]
            [ img [ class "logo-svg", src "elm_package_logo-grey.svg" ] []
            , span [ class "logo-text" ]
                [ span [ class "elm-name" ] [ text "elm" ]
                , span [ class "package-skimmer" ] [ text "package skimmer" ]
                ]
            ]
        , input
            [ class "search"
            , placeholder "Search"
            , value query
            , onInput Query
            , autofocus True
            ]
            []
        , span [ class "info" ] [ text <| "updated on " ++ refreshed ]
        ]


(=>) =
    (,)


viewPackages : List Package -> Html Msg
viewPackages pkgs =
    let
        viewPkg pkg =
            div
                [ class "package"
                ]
                [ h1 [ class "name" ] [ a [ href <| "http://package.elm-lang.org/packages/" ++ pkg.name ++ "/latest" ] [ text pkg.name ] ]
                , div [ class "summary" ] [ text <| pkg.summary ]
                , deprecationWarning pkg.deprecated
                , div [ class "metrics" ]
                    [ iconCount "star" "stars" pkg.stars
                    , iconCount "code-fork" "forks" pkg.forks
                    , iconCount "eye" "watchers" pkg.watchers
                    , iconCount "exclamation" "open issues" pkg.open_issues
                    , has "tests" pkg.has_tests
                    , has "examples" pkg.has_examples
                    , has "0.17 compatible" pkg.is_current
                    , case pkg.license of
                        Nothing ->
                            div [ class "metric" ]
                                [ i [ class <| "fa fa-legal" ] []
                                , text " No license"
                                ]

                        Just license ->
                            div [ class "metric" ]
                                [ i [ class <| "fa fa-legal" ] []
                                , text <| " " ++ license ++ " license"
                                ]
                    , img [ class "package-svg", src "elm_package_logo.svg" ] []
                    ]
                ]
    in
        div [ class "packages" ]
            (viewSidebar :: List.map viewPkg pkgs)


viewSidebar : Html Msg
viewSidebar =
    div [ class "sidebar" ]
        [ h2 [ class "top-header" ] [ text "Resources" ]
        , ul []
            [ li [] [ a [] [ text "Fancy Search" ] ]
            , li [] [ a [] [ text "Using Packages" ] ]
            , li [] [ a [] [ text "API Design Guidelines" ] ]
            , li [] [ a [] [ text "Write great docs" ] ]
            , li [] [ a [] [ text "Preview your docs" ] ]
            , li [] [ a [] [ text "Elm Website" ] ]
            ]
        , h2 [] [ text "Standard Packages" ]
        , ul []
            [ li []
                [ text "General"
                , ul []
                    [ li [] [ a [] [ text "core" ] ]
                    ]
                ]
            , li []
                [ text "Rendering"
                , ul []
                    [ li [] [ a [] [ text "html" ] ]
                    , li [] [ a [] [ text "svg" ] ]
                    , li [] [ a [] [ text "markdown" ] ]
                    ]
                ]
            , li []
                [ text "Effects"
                , ul []
                    [ li [] [ a [] [ text "http" ] ]
                    , li [] [ a [] [ text "geolocation" ] ]
                    , li [] [ a [] [ text "navigation" ] ]
                    , li [] [ a [] [ text "page-visibility" ] ]
                    , li [] [ a [] [ text "websocket" ] ]
                    ]
                ]
            , li []
                [ text "User Input"
                , ul []
                    [ li [] [ a [] [ text "mouse" ] ]
                    , li [] [ a [] [ text "window" ] ]
                    , li [] [ a [] [ text "keyboard" ] ]
                    ]
                ]
            ]
        ]


iconCount : String -> String -> Int -> Html Msg
iconCount icon label metric =
    span [ class "metric" ]
        [ i [ class <| "fa fa-" ++ icon ] []
        , text <| " " ++ toString metric ++ " " ++ label
        ]


deprecationWarning : Bool -> Html Msg
deprecationWarning deprecated =
    if deprecated then
        span [ class "deprecation-warning" ]
            [ i [ class "fa fa-exclamation" ] []
            , text " Deprecated"
            ]
    else
        span []
            []


has : String -> Bool -> Html Msg
has label metric =
    if metric then
        span [ class "metric" ]
            [ i [ class <| "fa fa-check-square-o" ] []
            , text <| " " ++ label
            ]
    else
        span [ class "metric" ]
            [ i [ class <| "fa fa-square-o" ] []
            , text <| " " ++ label
            ]