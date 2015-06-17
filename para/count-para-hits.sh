#!/bin/bash

set -e -u

source $(dirname $0)/../functions.sh

candidates=$1
lemmapair_ids=$2
# ^ from join-lemmas-on-ids.sh
fromfield=$3
# fromfield might contain several /-separated translations

<"${lemmapair_ids}" gawk \
    -v fromfield=${fromfield} \
    -v candf=$candidates '
  BEGIN { 
    OFS=FS="\t"
    while(getline<candf) {
      n=split($fromfield, froms, "/")
      for(i=1;i<=n;i++) {
        from=froms[i]
        cand[from][$2][$fromfield]++
      }
    }
  }
  $2 in cand && $3 in cand[$2] { 
    for(joined in cand[$2][$3]) {
      print joined, $3
      # "joined" might be a single translation, or several /-joined translations
    }
  }
  ' | to_freqlist
