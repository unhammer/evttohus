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
        cut -f1-2 <"${csv}" > "${tsv}"
    done

    for tsv in {smesmj,smanob,smasme}/*.tsv; do
        # normalise PoS names a bit:
        norm=$(echo "$tsv" | perl -wnpe '
          s/(\w+)_/\u\L$1_/;
          s/Cc_/CC_/; s/Cs_/CS_/; s/(Pp|Prep)_/Pr_/; s/P_/Po_/; s/I_/Ij_/;'
        )
        mv "${tsv}" "${norm}"
    done
)

test -d words-src-fad || mkdir words-src-fad
(
    cd words-src-fad
    dicts2tsv "[@src=\"fad\"]" nob sme
    touch nobsme/Pron_nobsme.tsv # just to stop pretty.sh from complaining
)
