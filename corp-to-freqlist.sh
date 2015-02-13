#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

lang=$1

xzcat freq/prepcorp.${lang}.xz | to_freqlist > freq/forms.${lang} & pid=$!
xzcat freq/prepcorp.${lang}.xz | ana ${lang} | lemma_per_line | to_freqlist > freq/lms.${lang}
wait ${pid}

LC_ALL=C join -j2 -t$'\t' \
    <(LC_ALL=C sort -k2,2 -t$'\t' freq/forms.${lang}) \
    <(LC_ALL=C sort -k2,2 -t$'\t' freq/lms.${lang}) \
    | awk 'BEGIN{OFS=FS="\t"} {print $2+$3,$1}' \
    | sort -nr \
    > freq/combined.${lang}
