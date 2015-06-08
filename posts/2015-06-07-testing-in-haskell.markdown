---
title: Testing in Haskell
---

Haskell is well known for its advanced type system and the safety and certainty
it brings to your code. I've read the phrase "if it compiles, it works" from
time to time. It is true that the type system catches a lot of mistakes early
on and prevents you from creating certain types of bugs. However, it still pays
of to write code tests in Haskell. That's why there are a couple of great
testing libraries like [QuickCheck][quickcheck] and [HUnit][hunit].

[quickcheck]: https://hackage.haskell.org/package/QuickCheck
[hunit]: https://hackage.haskell.org/package/HUnit

Since both have a different approach to testing (HUnit uses the more
traditional approach of xUnit architecture whereas QuickCheck does a type of
testing often called property testing), I would like to use both. After some
googling I found the [test-framework][test-framework] library that enables you
to do this easily. Another option is [tasty][tasty], I didn't try this but it
should work as well.

[test-framework]: https://hackage.haskell.org/package/test-framework
[tasty]: https://hackage.haskell.org/package/tasty

Trying to set up the tests took me a little longer than I would have liked, so
I'm documenting what I found here hoping that it will be of help to someone
(maybe it will help myself in a few months).

<!--more-->

The first thing you should do is add the following to your `.cabal` file

```
test-suite mytests
    type: exitcode-stdio-1.0
    main-is:
        Test.hs
    hs-source-dirs:
        test, src
    build-depends:
```

This is assuming that your tests are located in the `test` directory, the
source is located in the `src` directory and the main function calling your
tests is inside `Test.hs`.

The `build-depends` should contain all the same dependencies as the library or
executable you are testing, as well as the test libraries: `HUnit`,
`QuickCheck`, `test-framework`, `test-framework-hunit`,
`test-framework-quickcheck2`.

To correctly set up your environment do

```
cabal install --dependencies-only --enable-tests -j
cabal configure --enable-tests
cabal install -j
```

Now you're finally ready to run your tests by executing

```
cabal test
```
