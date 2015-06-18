#!/bin/bash

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
pos=$2

lang1=${dir%???}
lang2=${dir#???}

words_to_cmp () {
    lang=$1
    ana ${lang} \
        | grep -ve +Err/ -e +Der/ \
        | clean_cmp_ana ${lang} ${pos} \
        | gawk -f uniq_ana.awk \
        | grep -E -v -f badparts.${lang}.grep
}

srcf () {
    cat_dict ${lang1} ${lang2} ${pos} | cut -f1 | words_to_cmp ${lang1} ${pos} | sort -u
}

trgf () {
    cat_dict ${lang1} ${lang2} ${pos} | cut -f2- | tr '\t' '\n' | words_to_cmp ${lang2} ${pos} | sort -u
}

cat_dict ${lang1} ${lang2} ${pos} |sort -u \
    | grep -v '^[[:upper:]]' \
    | gawk -v srcf=<(srcf) -v trgf=<(trgf) -f precomp.awk \
    | gawk -v dict=<(cat_dict ${lang1} ${lang2} ${pos}) '
      BEGIN{
        OFS=FS="\t"
        while(getline<dict){ for(i=2;i<=NF;i++) d[$1][$i]=999 }
      }
      $1 && $2 { d[$1][$2]++ }
      END{
        for(src in d) {
          max=0
          min=9999999999
          for(trg in d[src]) {
            f=d[src][trg]
            if(f>max)max=f
            if(f<min)min=f
          }
          # Only print if all are the same frequency, or this is not the lowest freq:
          for(trg in d[src]) {
            f=d[src][trg]
            if(min==max || f>1) {
              print src,trg
            }
          }
        }
      }
  '

