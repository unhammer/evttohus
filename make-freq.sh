#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

lang=$1

if [[ $# -ge 2 ]]; then
    echo "Running convert2xml ..."
    convert_all $lang
else
    echo "Skipping convert2xml ..."
fi

test -d freq || mkdir freq

echo "ccat ..."
ccat_all $lang | xz - >freq/plaincorp.$lang.xz
echo "preprocess ..."
xzcat freq/plaincorp.$lang.xz | clean_punct | preprocess $lang | xz - > freq/prepcorp.$lang.xz

echo "to freqlist ..."
xzcat freq/prepcorp.$lang.xz | to_freqlist > freq/forms.$lang & pid=$!
xzcat freq/prepcorp.$lang.xz | ana $lang | lemma_per_line | to_freqlist > freq/lms.$lang
wait $pid
