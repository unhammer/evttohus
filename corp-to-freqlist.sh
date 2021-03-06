#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

lang=$1

xzcat freq/prepcorp.${lang}.xz | to_freqlist > freq/forms.${lang} & pid=$!
xzcat freq/prepcorp.${lang}.xz | ana_no_prep ${lang} | lemma_per_line | to_freqlist > freq/lms.${lang}
wait ${pid}

LC_ALL=C join -e0 -o0,1.1,2.1 -a1 -a2 -j2 -t$'\t' \
    <(LC_ALL=C sort -k2,2 -t$'\t' freq/forms.${lang}) \
    <(LC_ALL=C sort -k2,2 -t$'\t' freq/lms.${lang}) \
    | awk 'BEGIN{OFS=FS="\t"} {print $2+$3,$1}' \
    | sort -nr \
    > freq/combined.${lang}
