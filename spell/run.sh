#!/bin/bash

set -e -u

make

test -d out || mkdir out
test -d tmp || mkdir tmp

for lang in sma smj; do
    sed 's/[´`¨~<=>|°·‘§©@€*\&%+́–¼½¾¹]//g' ../freq/lms.${lang} \
        | cut -f2 \
        | grep '^[A-Za-zæøåÆØÅöäÖÄáÁŋŊńŃñÑ]\{3,\}$' \
        | LC_ALL=C sort -u \
                > tmp/${lang}.words.sorted
    ./comp.native tmp/${lang}.words.sorted tmp/${lang}.dawg
done


spell () {
    lang=$1
    f=$2
    dir=$3
    b=$(basename "$f")
    for edits in 1 2; do
        grep -v '^#' "$f" \
            | cut -f2- \
            | tr '\t' '\n' \
            | ./spell.native ${edits} tmp/${lang}.dawg \
            | tee tmp/${edits}.spelt."$b" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
                  > tmp/${edits}.sugg."$b"
        gawk -f join_sugg.awk -vsuggs=tmp/${edits}.sugg."$b" "$f" \
             > out/${dir}/"$b"_sugg${edits}
    done
}

test -d out/smesmj || mkdir out/smesmj
for f in ../out/smesmj/*; do
    spell smj "$f" smesmj
done
test -d out/nobsma || mkdir out/nobsma
for f in ../out/nobsma/*; do
    spell sma "$f" nobsma
done
