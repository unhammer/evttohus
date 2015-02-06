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

sort -u words-src-fad/$lang | ana sme \
    | grep +Cmp | sed 's/+[^#]*#*/	/g' | uniq_ana
