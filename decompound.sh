#!/bin/bash

# Restrict to words with src=fad:
words=words-src-fad
# Uncomment to try on all words:
#words=words

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
lang1=${dir%???}
lang2=${dir#???}
if [[ $# -eq 2 ]]; then
    precomp=true
    suff=precomp
else
    precomp=false
    suff=decomp
fi

test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

for pos in N V A; do
    dict=words/${dir}/${pos}_${dir}.tsv
    if [[ ! -f ${dict} ]]; then echo "${dict} doesn't exist"; continue; fi
    cat_dict () {
        if $precomp; then
            cat "${dict}" words/${dir}/${pos}_precomp.tsv
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
done
