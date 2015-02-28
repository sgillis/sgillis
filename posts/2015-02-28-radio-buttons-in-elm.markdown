---
title: Radio buttons and Elm
---

While working on a project with Elm, I needed to include some radio buttons in
a Elm generated form. While there is a [great example][form example] on how to
create forms with text inputs in Elm, I couldn't seem to find examples or
documentation on how to handle radio buttons.

[form example]: http://elm-lang.org/edit/examples/Intermediate/Form.elm

<!--more-->

Let's start with setting up the [basic skeleton][basic skeleton] for our simple
app.

[basic skeleton]: https://github.com/evancz/elm-architecture-tutorial

```
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Signal (..)


-- MODELS
type alias Model = { radio : String }

type Update = NoOp
            | Checked String

initialModel : Model
initialModel = { radio = "y" }


-- UPDATE

update : Update -> Model -> Model
update upd model = case upd of
    NoOp -> model
    Checked selection -> { model | radio <- selection }


-- VIEW

view : Model -> Html
view model = div [ ]
    [ text ("You selected: " ++ model.radio)
    , yesNoField "yesorno" Checked
    ]

yesNoField : String -> (String -> Update) -> Html
yesNoField fieldName toUpdate = div [ ]
    [ div [ ] [ input [ type' "radio"
                      , name fieldName
                      , value "y" ] [ ]
              , text "Yes" ]
    , div [ ] [ input [ type' "radio"
                      , name fieldName
                      , value "n" ]
                      [ ]
              , text "No" ]
    ]


-- SIGNALS

model : Signal Model
model = foldp update initialModel (subscribe updateChannel)

updateChannel : Channel Update
updateChannel = channel NoOp


-- MAIN
main : Signal Html
main = view <~ model
```

Going by the [form example][form example], we should now add a [`on` event][on]
to the input fields in the `yesNoField`.

[on]: http://package.elm-lang.org/packages/evancz/elm-html/2.0.0/Html-Events#on

```
input [ type' "radio"
      , name fieldName
      , value "y"
      , on "input" targetValue (send updateChannel << toUpdate) ]
```

However, it seems that the first argument to `on` is some kind of event name.
This is the correct one when using normal textual input fields, but it doesn't
work with radio buttons.

When faced with this problem, I started looking for other examples with radio
buttons or some documentation on what this event name variable could be.
Unfortunately I couldn't find anything. So I decided to dive into some of the
compiled Elm code to try and figure out what it should be.

To do this I compiled `Radio.elm` with `elm-make` and wrote a simple
`index.html` to [manually embed the `elm.js` source code and run it][embed].

[embed]: http://elm-lang.org/learn/Components.elm

The source code for the [`on` function][on source] shows that it is nothing
more than the [`VirtualDom.on` function][virtualdom on source]. This `on`
function is apparently just returning a property, that will be added to the
proper HTML tag by Elm, so we need to dig a little deeper.

[on source]: https://github.com/evancz/elm-html/blob/master/src/Html/Events.elm#L32-L33
[virtualdom on source]: https://github.com/evancz/virtual-dom/blob/master/src/Native/VirtualDom.js#L1762-L1772

By searching through the source code on `delegator`, I stumbled upon the
interesting looking `createHandler` and `findAndInvokeListeners` functions. By
adding `console.log(eventName);` at the top of `findAndInvokeListeners` I got
some interesting output

```
mousedown
focus
focusIn
mouseup
change
click
```

I figured change was the way to go. So let's try it. Change `yesNoField` to

```
yesNoField : String -> (String -> Update) -> Html
yesNoField fieldName toUpdate = div [ ]
    [ div [ ] [ input [ type' "radio"
                      , name fieldName
                      , value "y"
                      , on "change" targetValue (send updateChannel << toUpdate)
                      ] [ ]
              , text "Yes" ]
    , div [ ] [ input [ type' "radio"
                      , name fieldName
                      , value "n"
                      , on "change" targetValue (send updateChannel << toUpdate)
                      ]
                      [ ]
              , text "No" ]
    ]
```

When you recompile and refresh, everything should be working.

### Conclusion

Is it difficult to get radio buttons working in Elm? No. You just need to add
the `on "change" targetValue someMessage` attribute to your `input` and wire up
this message like you would do with any other messages.

The tricky part was in finding the correct value `"change"`. As far as I could
tell there is no real documentation on the possible values and when to use
which ones. Elm might benefit from defining an algebraic data type for this
argument.
