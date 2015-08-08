---
title: Native modules in Elm
---

Since Elm compiles to JavaScript, every function you use in Elm should have a
translation to a normal JavaScript function that will be executed in the
browser. Those basic building blocks that make up Elm are defined in the
`Native` modules of the [elm-lang core](https://github.com/elm-lang/core).

While I was working on the [Chrome
app](https://chrome.google.com/webstore/detail/mooltipass-app/cdifokahonpfaoldibbjmbkdhhelblpj)
for the [Mooltipass](http://www.themooltipass.com/), I needed to change one of
those native JavaScript functions on which Elm is based. We are using the
[`dropDown`](https://github.com/elm-lang/core/blob/4dfe74bfab249929a848e42dd811725cf0f4a146/src/Graphics/Input.elm#L104-L109)
function to create a dropdown HTML element, but the problem was that there was
no way to say which element had been selected. So we needed to add an extra
argument to the function that would be used to indicate the selected element.

<!--more-->

[Conrad Parker](https://github.com/kfish) solved this [a while
ago](https://github.com/sgillis/mooltipass.hid-app/commit/3c8ac895557641e19481897c76743590cd26d6d4).
At that time the source code contained a copy of the elm-lang core libraries
because of a bug that was present in one of the older version of the core
libraries. So his fix was made in the core libraries as well.

Because I upgraded the core libraries to the latest version, I stumbled unto
this bug again. So I wanted to fix it again, but in a way that would not break
if we update the core libraries again.

To do this I first created my own `dropDown` function which just calls some
custom JavaScript function.

```
dropDown : (a -> Signal.Message) -> List (String, a) -> String -> Element
dropDown = Native.CustomGraphics.dropDown
```

The custom JavaScript function is just the function that was written by Conrad.
I extracted the part about the dropDown from `Native.Graphics.Input` in the
core libraries, and put this my own [`Native/CustomGraphics.js`
file](https://github.com/sgillis/mooltipass.hid-app/blob/a41c400a105c9affa0d480d4a4ab7bf458089383/src/gui/Native/CustomGraphics.js).
This just defines a `make` function that returns all functions that can be
used, which in this case is just the `dropDown` function.

To be able to use this in our Elm app, we still need to be able to tell Elm
where it can reach this function. So the first thing we need to do is load the
native JavaScript file in the HTML page that loads the Elm code.

```
<script type="text/javascript" src="Native/CustomGraphics.js"></script>
```

But this is not enough. When Elm compiles the `.elm` file where we use the
`dropDown` function, it needs to have access to the native module we just
defined. Normally when you create an Elm module, Elm makes sure the right
native files are accesible in the compiled JavaScript code. It does this by
calling the `make` file we just created and savind the result in a variable.
When we look at the compiled code that uses the custom `dropDown` function we
defined earlier, it contains this line.

```
Elm.CustomGraphics.make = function (_elm) {
    ...
    $moduleName = "CustomGraphics",
    ...
    var dropDown = $Native$CustomGraphics.dropDown;
    ...
```

When we try to run this code, Elm will complain it doesn't know this
`$Native$CustomGraphics` variable. In order to do this, I added a small step to
the Makefile that builds the source code. After Elm is done compiling the
source code, I run a regex expression on the file that adds the definition for
`$Native$CustomGraphics`.

```
sed -i.bak "s/\(\$$moduleName = \"CustomGraphics\",\)/\1 \$$Native\$$CustomGraphics = Elm.Native.CustomGraphics.make(_elm),/" elm.js
```

This changes the line

```
$moduleName = "CustomGraphics",
```

to

```
$moduleName = "CustomGraphics", $Native$CustomGraphics =
Elm.Native.CustomGraphics.make(_elm),
```

which is the `make` function we defined earlier. Now we can run the code with
our modified `dropDown` function without changing the core libraries, hurray!

I haven't figured out yet how Elm decides at compile time which
JavaScript files need to be loaded in the resulting JavaScript file, or how it
decides which specific `make` functions need to be called in order to have the
right native functions available. It would be interesting to try and hook into
the compile process and tell the compiler where it needs to use our custom
JavaScript module instead of hacking it in with a regex.
