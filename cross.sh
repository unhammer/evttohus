#!/bin/bash

# Usage:
# ./cross.sh nob sme sma N

srclang=$1
midlang=$2
trglang=$3
pos=$4

revtsv () {
    gawk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $i,$1}' "$@"
}
cat_dict () {
    l1=$1
    l2=$2
    pos=$3
    cat words/${l2}${l1}/${pos}.tsv | revtsv | cat - words/${l1}${l2}/${pos}.tsv
}

<fadwords/${pos}.${srclang} gawk \
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
      print src,mid
      for(trg in mid_trg[mid]) {
        print src,trg
      }
    }
  }
}
'
