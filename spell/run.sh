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

for f in fad.sme.smjifisert-*verb; do
    for n in 1 2; do
        cut -f2 "$f" \
            | ./spell.native $n tmp/smj.dawg \
            | tee out/$n.spelt."$f" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > out/$n.sugg."$f"
    done
done
