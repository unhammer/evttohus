#!/bin/bash

# Usage:
# ./cross.sh nob sme sma N

set -e -u
source functions.sh

srclang=$1
midlang=$2
trglang=$3
pos=$4

cat_dict () {
    l1=$1
    l2=$2
    pos=$3
    gawk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $i,$1}' words/${l2}${l1}/${pos}.tsv && # reversed
    gawk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $1,$i}' words/${l1}${l2}/${pos}.tsv
}

if ${FAD_ONLY}; then
    words=fadwords
else
    words=words
fi
<${words}/${pos}.${srclang} gawk \
    -v src_mid_f=<(cat_dict ${srclang} ${midlang} ${pos}) \
    -v mid_trg_f=<(cat_dict ${midlang} ${trglang} ${pos}) '
BEGIN{
  OFS=FS="\t"
  while(getline<src_mid_f)src_mid[$1][$2]++
  while(getline<mid_trg_f)mid_trg[$1][$2]++
}
{
  src = $0
}
src in src_mid {
  for(mid in src_mid[src]) {
    #print src,mid
    if(mid in mid_trg) {
      #print src,mid
      for(trg in mid_trg[mid]) {
        print src,trg
      }
    }
  }
}
'
