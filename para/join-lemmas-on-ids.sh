#!/bin/bash

set -e -u

source $(dirname $0)/../functions.sh

sents1=$1
sents2=$2

id_lemmas () {
    # Prepend sentence id to each lemma
    gawk '
      BEGIN{ OFS=FS="\t" }
      /<s / { sub(/.*id="/,""); sub(/".*/,""); id=$0 }
      { $1="";gsub(/\t/,"") }
      id { print id,$0 }
    ' | sort -u
}

join -t$'\t' -j1 \
    <(id_lemmas <"${sents1}") \
    <(id_lemmas <"${sents2}")
