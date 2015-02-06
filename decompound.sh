#!/bin/bash

set -e -u

source functions.sh
lang=$1

uniq_ana () {
    # not enough to run uniq since each ana-group is not sorted
    awk '
BEGIN{OFS=FS="\t"; }
$1!=form {
    if(length(cohort)>0) {
      for(r in cohort) print r
      for(r in cohort) delete cohort[r]
    }
}
END {
    if(length(cohort)>0) {
      for(r in cohort) print r
    }
}
{
  form=$1
  cohort[$0]++
}
'
}


cat <(cut -f1  words-src-fad/${lang}???/N_*.tsv) \
    <(cut -f2- words-src-fad/???${lang}/N_*.tsv | tr '\t' '\n') \
    | sort -u \
    | ana sme \
    | grep '+Cmp#.*+N[^#]*$' \
    | sed 's/+[^#]*#*/	/g;s/	$//' \
    | uniq_ana \
    | gawk -vdict=words/smesmj/N_smesmj.tsv -f compound-translate.awk
