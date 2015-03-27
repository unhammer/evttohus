#!/bin/bash

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
pos=$2

lang1=${dir%???}
lang2=${dir#???}

cat_dict () {
    cat words/${dir}/${pos}.rev words/${dir}/${pos}.tsv
}

words_to_cmp () {
    lang=$1
    ana ${lang} \
        | grep -v +Err/ \
        | clean_cmp_ana ${lang} ${pos} \
        | gawk -f uniq_ana.awk \
        | grep -E -v -f badparts.${lang}.grep
}

srcf () {
    cat_dict | cut -f1 | words_to_cmp ${lang1} ${pos}
}

trgf () {
    cat_dict | cut -f2- | tr '\t' '\n' | words_to_cmp ${lang2} ${pos}
}

cat_dict \
    | grep -v '^[[:upper:]]' \
    | gawk -v srcf=<(srcf) -v trgf=<(trgf) -f precomp.awk \
    | sort -u
