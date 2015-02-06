#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

test -d words || mkdir words
(
    cd words
    dicts2tsv "" nob sma sme smj

    # smesmj has lots of stuff in a csv format that hasn't been converted to XML yet:
    dir=smesmj
    for csv in $GTHOME/words/dicts/$dir/src/*.csv; do
        tsv=$dir/$(basename "$csv")
        tsv=${tsv%%.csv}.tsv
        # "normalise" PoS names:
        tsv=$(echo "$tsv"|perl -wnpe 's/(\w+)_/\u\L$1_/;s/Cc_/CC_/;s/Cs_/CS_/;s/(Pp|Prep)_/Pr_/;s/P_/Po_/;')
        cut -f1-2 <"${csv}" > "${tsv}"
    done
)

test -d words-src-fad || mkdir words-src-fad
(
    cd words-src-fad
    dicts2tsv "[@src=\"fad\"]" nob sme
)
