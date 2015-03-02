#!/bin/bash

# Restrict to words with src=fad:
words=fadwords
# Uncomment to try on all words:
#words=words

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
lang1=${dir%???}
lang2=${dir#???}
pos=$2
if [[ $# -eq 3 ]]; then
    precomp=true
    suff=precomp
else
    precomp=false
    suff=decomp
fi

dict=words/${dir}/${pos}.tsv
if [[ ! -f ${dict} ]]; then echo "${dict} doesn't exist"; continue; fi
cat_dict () {
    if $precomp; then
        cat "${dict}" words/${dir}/precomp_${pos}.tsv
    else
        cat "${dict}"
    fi
}
echo -n "${pos} compound analyses found: " >&2
< ${words}/${pos}.${lang1} ana ${lang1} \
    | clean_cmp_ana ${lang1} ${pos} \
    | gawk -f uniq_ana.awk \
    | tee >(wc -l >&2) \
    | gawk -v dict=<(cat_dict) -f compound_translate.awk \
    | awk -F'\t' '$2' \
    > out/${dir}/${pos}_${suff}
echo -n "${pos} compounds translated:    " >&2
grep -v '^#' out/${dir}/${pos}_${suff}|cut -f1|sort -u| wc -l >&2
