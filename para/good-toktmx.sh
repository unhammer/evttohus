#!/bin/bash

set -e -u

lang1=$1
lang2=$2

dir=${lang1}2${lang2}

find $GTFREE/toktmx/"${dir}" -type f -name '*.toktmx' -print0 \
    | xargs -0 -I{} "$(dirname $0)"/toktmx2tsv-lines.sh "${lang1}" "${lang2}" '{}' \
    | awk -v src="${lang1}" -v trg="${lang2}" '
BEGIN{
  OFS=FS="\t"
}
$1==src {
  srcseg=$2
}
$1==trg {
  trgseg=$2

  sl=length(srcseg)
  tl=length(trgseg)
  ld=nl-tl
  if(ld<0){ ld=-ld }            # abs

  # Heuristics: only include sentences of a certain length, that are
  # different, and that have less than a certain difference in length:
  if(ld<30 && tl>5 && sl>5 && srcseg!=trgseg) {
    print src, srcseg
    print trg, trgseg
    print ""
  }
}
'
