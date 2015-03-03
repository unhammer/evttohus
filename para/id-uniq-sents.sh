#!/bin/bash

# sort -u sentence pairs and prepend xml tags with sentence id's

set -e -u

source $(dirname $0)/../functions.sh

uniq_para () {
    awk -F'\t' '/^$/{for(p in pair)printf "%s\t%s\t",p,pair[p]; print ""; for(p in pair)delete pair[p]} $2 {pair[$1]=$2}' \
        | sort -u \
        | awk -F'\t' '$2{print $1"\t"$2"\n"$3"\t"$4"\n"}'
}

cat "$@" \
    | tr -d '<>' \
    | uniq_para \
    | awk 'BEGIN{OFS=FS="\t"; id=0} /^$/{id++} {print "<s xml:lang=\""$1"\" id=\""id"\"\/>"$2 }' \
