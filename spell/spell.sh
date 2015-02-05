#!/bin/bash

set -e -u

make

sed 's/[´`¨~<=>|°·‘§©@€*\&%+́–¼½¾¹]//g' form-freqlist.smj \
    | cut -f2 \
    | grep '^[A-Za-zæøåÆØÅöäÖÄáÁŋŊńŃñÑ]\{3,\}$' \
    | LC_ALL=C sort -u \
    > smj.words.sorted

./comp.native smj.words.sorted smj.dawg

for f in fad.sme.smjifisert-*verb; do
    for n in 1 2; do
        cut -f2 "$f" \
            | ./spell.native $n smj.dawg \
            | tee $n.spelt."$f" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > $n.sugg."$f"
    done
done
