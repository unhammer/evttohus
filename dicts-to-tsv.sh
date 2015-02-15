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

    # We only use files named $dir/$pos_$dir.tsv, e.g.
    # smenob/V_smenob.tsv; append some entries from the more funnily
    # named files:
    for f in */[VNA]_{Pl,G3,mwe,NomAg}_* ; do
        [[ -f $f ]] || continue
        b=$(basename "$f")
        pos=${b%%_*};dir=$(dirname "$f")
        cat "$f" >> "${dir}"/"${pos}_${dir}.tsv"
    done
    
)

test -d words-src-fad || mkdir words-src-fad
(
    cd words-src-fad
    dicts2tsv "[@src=\"fad\"]" nob sme
    touch nobsme/Pron_nobsme.tsv # just to stop pretty.sh from complaining

    # Split words into verbs and nonverbs:
    for lang in sme nob; do
        for pos in V N A; do
            mono_from_bi ${lang} ${pos} > ${pos}.${lang}
        done
        mono_from_bi ${lang} "[^VNA]" > nonVNA.${lang}
    done
)
