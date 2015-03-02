#!/bin/bash

set -e -u

source ../functions.sh

lang1=nob
lang2=sma

file=$1

cat ../scratch/${lang2}2${lang1}.good \
    | tr -d '<>' \
    | awk 'BEGIN{OFS=FS="\t"; id=0} /^$/{id++} {print "<s xml:lang=\""$1"\" id=\""id"\"\/>"$2 }' \
    > ../tmp/with-id

nob-seen () {
    grep "^<s xml:lang=\"${lang1}\"" ../tmp/with-id \
        | ana ${lang1} --xml \
        | ana_to_lemmas \
        | gawk -v f=$1 'BEGIN{OFS=FS="\t"; while(getline<f)n[$1]++ }
/<s/{sub(/.*id="/,"");sub(/".*/,"");id=$0}
{$1="";gsub(/\t/,"")}
id && $0 in n {print id,$0}
'
}

sma-seen () {
    grep "^<s xml:lang=\"${lang2}\"" ../tmp/with-id \
        | ana ${lang2} --xml \
        | ana_to_lemmas \
        | gawk -v f=$1 'BEGIN{OFS=FS="\t"; while(getline<f)n[$2]++ }
/<s/{sub(/.*id="/,"");sub(/".*/,"");id=$0}
{$1="";gsub(/\t/,"")}
id && $0 in n {print id,$0}
'
}

join -t$'\t' -j1 <(nob-seen  "${file}"|sort -u) <(sma-seen "${file}" |sort -u)
