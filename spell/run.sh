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
    for edits in 1 2; do
        grep -v '^#' "$f" \
            | cut -f2- \
            | tr '\t' '\n' \
            | ./spell.native ${edits} tmp/smj.dawg \
            | tee out/${edits}.spelt."$b" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > out/${edits}.sugg."$b"
        gawk -f join_sugg.awk -vsuggs=out/${edits}.sugg."$b" "$f" \
            > out/${edits}.sme.sugg."$b"
    done
done
