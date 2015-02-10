#!/bin/bash

set -e -u

make

test -d out || mkdir out
test -d tmp || mkdir tmp

sed 's/[´`¨~<=>|°·‘§©@€*\&%+́–¼½¾¹]//g' form-freqlist.smj \
    | cut -f2 \
    | grep '^[A-Za-zæøåÆØÅöäÖÄáÁŋŊńŃñÑ]\{3,\}$' \
    | LC_ALL=C sort -u \
    > tmp/smj.words.sorted

./comp.native tmp/smj.words.sorted tmp/smj.dawg

for f in ../out/smesmj/*; do
    b=$(basename "$f")
    for max_edits in 1 2; do
        grep -v '^#' "$f" \
            | cut -f2- \
            | tr '\t' '\n' \
            | ./spell.native ${max_edits} tmp/smj.dawg \
            | tee out/$n.spelt."$b" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > out/$n.sugg."$b"
        gawk -f join_sugg.awk -vsuggs=out/$n.sugg."$b" "$f" \
            > out/$n.sme.sugg."$b"
    done
done
