#!/bin/bash

### Usage:
# para/kwic.sh freq/smesmj.sents.ids freq/smesmj.lemmas.ids out/nobsmjsme/*_sme

### TODO: not actually kwic yet, just full sentences …

set -e -u

sents_ids=$1
lemmas_ids=$2
shift
shift

b=$(basename "${sents_ids}")
dir=${b%%.*}
lang1=${dir%???}
lang2=${dir#???}

<"${lemmas_ids}" gawk \
    -v sents_ids="${sents_ids}" -v candidates=<(cat "$@") \
    -v lang1=${lang1} -v lang2=${lang2} '
  BEGIN {
    FS="<s xml:lang=\"|\" id=\"|\"/>"
    while(getline<sents_ids) sent[$3][$2]=$4
    OFS=FS="\t"
    while(getline<candidates) if($1) cand[$1][$2]++
  }
  $1 in sent && $2 in cand && $3 in cand[$2]{
    print $2,$3,sent[$1][lang1],sent[$1][lang2]
  }' | sort -u
