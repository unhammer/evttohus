#!/bin/bash

#!/bin/bash

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
lang1=${dir%???}
lang2=${dir#???}
pos=$2

cat_dict () {
    cat words/${dir}/${pos}.tsv words/${dir}/${pos}.rev
}

< fadwords/${pos}.${lang1} gawk \
    -v dict=<(cat_dict) \
    -v synf=<(synonyms ${lang1} ${pos}) '
BEGIN{
  OFS=FS="\t"
  while(getline<synf)s[$1][$2]++
  while(getline<dict)for(i=2;i<=NF;i++)d[$1][$i]++
}
$0 in s{
  fad=$0
  for(syn in s[fad]) {
    if(syn in d) {
      for(trg in d[syn]) {
        if(!(fad in d)) {
          # TODO: might also want to "|| !(trg in d[fad])"  to generate alternate
          # <t>-entries for existing <tg>
          print fad,trg
        }
      }
    }
  }
}
' | sort -u
