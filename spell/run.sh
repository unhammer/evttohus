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
        sed "s/$/${tab}F/" ../words/${lang}.${pos} \
            | cat - ../words/${lang}.[^${pos}] \
            | cleanwords > tmp/${lang}.${pos}.sorted
        ./comp.native tmp/${lang}.${pos}.sorted tmp/${lang}.${pos}.dawg
    done
    for pos in nonVNA; do
        sed "s/$/${tab}F/" ../words/${lang}.* \
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
            | ./spell.native ${edits} ${decomp} tmp/${lang}.dawg \
            | tee tmp/${edits}.spelt."$b" \
            | awk -F'\t' '/IN_CORPUS/{next}$2{print}' \
            > tmp/${edits}.sugg."$b"
        gawk -f join_sugg.awk -vsuggs=tmp/${edits}.sugg."$b" "$f" \
            | LC_ALL=C sort -u \
            | LC_ALL=C comm -23 - <(LC_ALL=C sort -u "$f") \
            > out/${dir}/"$b"_sugg${edits}
    done
}

echo "Spelling ..."
test -d out/smesmj || mkdir out/smesmj
for f in ../out/smesmj/*; do
    if [[ -f "$f" ]]; then
        spell smj "$f" smesmj
    else
        echo "couldn't find $f"; exit 1
    fi
done
test -d out/nobsma || mkdir out/nobsma
for f in ../out/nobsma/*; do
    if [[ -f "$f" ]]; then
        spell sma "$f" nobsma
    else
        echo "couldn't find $f"; exit 1
    fi
done
