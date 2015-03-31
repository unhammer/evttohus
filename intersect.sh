#!/bin/bash

### Usage:
# mkdir work/
# ./intersect.sh work/ out/nobsmjsme/N_*_ana_00_*

### This will copy the given files into work/, but if, for any nob
### word, there was a nob-smj pair in more than one file, all pairs
### with that nob-word will end up in work/intersection. The resulting
### files will have no duplicates.

# TODO: should be intersection_singles vs intersection_multis

set -e -u

outdir=$1
shift

rev_blocks () {
    f=$1
    b=$(basename "$f")
    if [[ $b = *_sme ]]; then groupfield=3; else groupfield=1; fi
    revfield=$(( 8 - ${groupfield} ))
    <"$f" rev | LC_ALL=C sort -k${revfield},${revfield} -k6,6 -t$'\t' | rev \
            | gawk -F'\t' -v g=${groupfield} '
      # Just print an empty line whenever the source word changes:
      prev != $g { print "" }
      {
        print
        prev = $g
      }'
}

tmp=$(mktemp -d -t evttohus.XXXXXXXXX)
trap 'rm -rf "${tmp}"' EXIT

gawk -v out="${tmp}" 'BEGIN{OFS=FS="\t"}
function basename (f) {
  cmd="basename "f; cmd | getline b; close(cmd); return b
}
/./{
  if($1 in seen && $2 in seen[$1]) dup[$1][$2]=$0
  seen[$1][$2][FILENAME]=$0
}
END {
  for(nob in dup) {
    if(length(dup[nob])==1) {
      curf=out"/intersection_singles"
    }
    else {
      curf=out"/intersection_multis"
    }
    for(smj in dup[nob]){
      print dup[nob][smj] > curf
    }
  }
  for(nob in seen) if(!(nob in dup)) for(smj in seen[nob]) for(f in seen[nob][smj]) {
    print seen[nob][smj][f] > out"/"basename(f)
  }
}
' "$@"



for f in ${tmp}/*; do
    b=$(basename "$f")
    rev_blocks "$f" >"${outdir}/$b"
done

