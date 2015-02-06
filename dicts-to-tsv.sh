#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

test -d words || mkdir words
(
    cd words
    dicts2tsv "" nob sma sme smj
)

test -d words-src-fad || mkdir words-src-fad
(
    cd words-src-fad
    dicts2tsv "[@src=\"fad\"]" nob sme
)
