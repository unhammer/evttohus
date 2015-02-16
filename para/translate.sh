#!/bin/bash

set -e -u

cd "$(dirname "$0")"/..
source functions.sh

lang1=nob
lang2=sma

cat words/${lang1}${lang2}/*_${lang1}${lang2}.tsv \
    <(awk -F'\t' '{for(i=2;i<=NF;i++)print $i,$1}' words/${lang2}${lang1}/*_${lang2}${lang1}.tsv ) \
    | sed 's/_SWE//g' \
    | sort -u > tmp/all_${lang1}${lang2}.tsv
# treat SWE as norwegianwhynot

# TODO: not all translations are into lemmas, need to lemmatise translations as well

cat scratch/${lang2}2${lang1}.good \
    | tr -d '<>' \
    | awk 'BEGIN{OFS=FS="\t"; id=0} /^$/{id++} {print "<s xml:lang=\""$1"\" id=\""id"\"\/>"$2 }' \
    > tmp/with-id

grep "^<s xml:lang=\"${lang1}\"" tmp/with-id \
    | ana ${lang1} --xml \
    | ana_to_lemmas \
    | gawk -v dict=tmp/all_${lang1}${lang2}.tsv -f compound_translate.awk \
    > tmp/with-id-${lang1}-translated

grep "^<s xml:lang=\"${lang2}\"" tmp/with-id \
    | ana ${lang2} --xml \
    | ana_to_lemmas \
    > tmp/with-id-${lang2}

paste tmp/with-id-${lang1}-translated tmp/with-id-${lang2}
