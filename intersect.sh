#!/bin/bash

### Usage:
# mkdir work/
# ./intersect.sh work/ out/nobsmjsme/N_*_ana_00_*

srclang=sme
# The source langauge in the _output_ files that we want to check

### This will copy the given files into work/, but if, for any src
### word, there was a src-trg pair in more than one file, all pairs
### with that src-word will end up in work/intersection. The resulting
### files will have no duplicates.

# TODO: should be intersection_singles vs intersection_multis

set -e -u

outdir=$1
shift

rev_blocks () {
    f=$1
    b=$(basename "$f")
    case "$b" in
        *_${srclang} ) groupfield=1;;
        intersection* ) groupfield=1;;
        * ) groupfield=3;;
    esac
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

gawk -v out="${tmp}" '
BEGIN{OFS=FS="\t"}
function basename (f) {
  cmd="basename "f; cmd | getline b; close(cmd); return b
}
/./{
  if($1 in seen && $2 in seen[$1]) dup[$1][$2]=$0
  seen[$1][$2][FILENAME]=$0
}
END {
  for(src in dup) {
    if(length(dup[src])==1) {
      curf=out"/intersection_singles"
    }
    else {
      curf=out"/intersection_multis"
    }
    for(trg in dup[src]){
      print dup[src][trg] > curf
    }
  }
  for(src in seen) if(!(src in dup)) for(trg in seen[src]) for(f in seen[src][trg]) {
    print seen[src][trg][f] > out"/"basename(f)
  }
}
' "$@"



for f in ${tmp}/*; do
    b=$(basename "$f")
    rev_blocks "$f" >"${outdir}/$b"
done

