#!/bin/bash

set -e -u

dir=smesmj

make

test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}
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
            | tee tmp/${edits}.spelt."$b" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > tmp/${edits}.sugg."$b"
        gawk -f join_sugg.awk -vsuggs=tmp/${edits}.sugg."$b" "$f" \
            > out/${dir}/"$b"_sugg${edits}
    done
done
