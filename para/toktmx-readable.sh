#!/bin/bash

set -e -u

shopt -s extglob

file=$1
tmp=${file##*([^/])*(/)}
langs=${tmp%%/*}
lang1=${langs%%2*}
lang2=${langs##*2}

xmlstarlet sel -t \
           -m "//tu" \
             -o "${lang1}	" -v "./tuv[@xml:lang='${lang1}']/seg/text()" -n \
             -o "${lang2}	" -v "./tuv[@xml:lang='${lang2}']/seg/text()" -n \
             -n \
           "${file}"
