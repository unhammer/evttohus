#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

lang=$1

if [[ $# -ge 2 ]]; then
    echo "Converting corpora ..."
    convert_all $lang
else
    echo "Skipping corpus conversion ..."
fi

test -d freq || mkdir freq

ccat_all $lang | clean_punct | preprocess $lang | xz - > freq/corpus.$lang.xz

xzcat *.$lang.xz | to_freqlist > freq/forms.$lang & pid=$!
xzcat *.$lang.xz | ana $lang | lemma_per_line | to_freqlist > freq/lms.$lang
wait $pid
