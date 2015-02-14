#!/bin/bash

set -e -u

# Restrict to words with src=fad:
words=words-src-fad
# Uncomment to try on all words:
#words=words

source functions.sh
dir=$1
lang1=${dir%???}
lang2=${dir#???}


test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

for pos in N V A; do
    dict=words/${dir}/${pos}_${dir}.tsv
    if [[ ! -f ${dict} ]]; then echo "${dict} doesn't exist"; continue; fi
    echo -n "${pos} compound analyses found: " >&2
    cat <(cut -f1  ${words}/${lang1}???/${pos}_*.tsv) \
        <(cut -f2- ${words}/???${lang1}/${pos}_*.tsv | tr '\t' '\n') \
        | sort -u \
        | ana ${lang1} \
        | clean_cmp_ana ${lang1} ${pos} \
        | gawk -f uniq_ana.awk \
        | tee >(wc -l >&2) \
        | gawk -v dict=${dict} -f compound_translate.awk \
        > out/${dir}/${pos}_decomp
    echo -n "${pos} compounds translated:    " >&2
    grep -v '^#' out/${dir}/${pos}_decomp|cut -f1|sort -u| wc -l >&2
done
