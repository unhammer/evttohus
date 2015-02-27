#!/bin/bash

set -e -u

make

test -d out || mkdir out
test -d tmp || mkdir tmp

tab=$'\t'

cleanwords () {
    sed 's/[´`¨~<=>|°·‘§©@€*\&%+́–¼½¾¹]//g' \
        | grep "^[A-Za-zæøåÆØÅöäÖÄáÁŋŊńŃñÑïÏ]\{3,\}\($\|${tab}\)" \
        | LC_ALL=C sort -u
}

echo "Compiling dictionaries ..."
for lang in sma smj; do
    for pos in V N A; do
        # "make words/sme.N" and so on for this:
        sed "s/$/${tab}F/" ../words/${pos}.${lang} \
            | cat - ../words/[^${pos}].${lang} \
            | cleanwords > tmp/${lang}.${pos}.sorted
        ./comp.native tmp/${lang}.${pos}.sorted tmp/${lang}.${pos}.dawg
    done
    for pos in nonVNA; do
        sed "s/$/${tab}F/" ../words/*.${lang} \
            | cleanwords > tmp/${lang}.${pos}.sorted
        ./comp.native tmp/${lang}.${pos}.sorted tmp/${lang}.${pos}.dawg
    done
done


spell () {
    lang=$1
    f=$2
    dir=$3
    b=$(basename "$f")
    decomp=1
    pos=${b%%_*}
    for edits in 1 2; do
        grep -v '^#' "$f" \
            | cut -f2- \
            | tr '\t' '\n' \
            | ./spell.native ${edits} ${decomp} tmp/${lang}.${pos}.dawg \
            | tee tmp/${dir}_"$b"_spelt${edits} \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > tmp/${dir}_"$b"_sugg${edits}
        gawk -f join_sugg.awk -vsuggs=tmp/${dir}_"$b"_sugg${edits} "$f" \
            | LC_ALL=C sort -u \
            | LC_ALL=C comm -23 - <(LC_ALL=C sort -u "$f") \
            > out/${dir}/"$b"_sugg${edits}
    done
}

echo "Spelling ..."
for dir in smesmj nobsmj nobsma; do
    trg=${dir#???}
    test -d out/${dir} || mkdir out/${dir}
    for f in ../out/${dir}/*; do
        if [[ -f "$f" ]]; then
            spell smj "$f" ${dir}
        else
            echo "couldn't find $f"; exit 1
        fi
    done
done
