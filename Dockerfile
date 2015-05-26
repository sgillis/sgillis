FROM haskell

ADD . /src/sgillis
WORKDIR /src/sgillis
RUN cabal update && cabal install -j
