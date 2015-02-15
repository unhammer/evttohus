#!/bin/bash

set -e -u

cd "$(dirname "$0")"/..
source functions.sh

lang=nob

grep "^${lang}" scratch/sma2nob.good \
    | tr -d '<>' \
    | sed 's/^.../<s xml:lang="&"\/>/' \
    | ana ${lang} --xml \
    | ana_to_lemmas \
    | gawk -v dict=words/nobsma/N_nobsma.tsv -f compound_translate.awk

