#!/bin/bash

set -e -u

# Restrict to words with src=fad:
words=words-src-fad
# Uncomment to try on all words:
#words=words

source functions.sh
lang1=$1
lang2=$2
dir=${lang1}${lang2}

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


test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

for pos in N V A; do
    dict=words/${dir}/${pos}_${dir}.tsv
    echo -n "${pos} compound analyses found: " >&2
    cat <(cut -f1  ${words}/${lang1}???/${pos}_*.tsv) \
        <(cut -f2- ${words}/???${lang1}/${pos}_*.tsv | tr '\t' '\n') \
        | sort -u \
        | ana ${lang1} \
        | grep "+Cmp#.*+${pos}[^#]*$" \
        | tee >(wc -l >&2) \
        | sed 's/+[^#]*#*/	/g;s/	$//' \
        | uniq_ana \
        | gawk -vdict=${dict} -f compound-translate.awk \
        > out/${dir}/${pos}.decomp
    echo -n "${pos} compounds translated:    " >&2
    grep -v '^#' out/${dir}/${pos}.decomp | wc -l >&2
done
