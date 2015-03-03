#!/bin/bash

set -e -u

dir=$1
lang1=${dir%???}
lang2=${dir#???}
no_examples=$2

dir2=${lang1}2${lang2}

find $GTFREE/toktmx/"${dir2}" -type f -name '*.toktmx' -print0 \
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
  ld=sl-tl
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

if ! ${no_examples}; then
    if [[ $lang1$lang2 = nobsma || $lang1$lang2 = smanob ]]; then
        xmlstarlet sel -t -m '//xg' \
            -o "${lang1}"$'\t' -c './x/text()' -n \
            -o "${lang2}"$'\t' -c './xt/text()' -n \
            -n \
            $GTHOME/words/dicts/${lang1}${lang2}/src/*.xml
    fi
fi
