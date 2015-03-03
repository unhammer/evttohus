#!/bin/bash

set -e -u

source $(dirname $0)/../functions.sh

candidates=$1
lemmapair_ids=$2
# ^ from combine-ana-sents

<"${lemmapair_ids}" gawk -v f=$candidates '
  BEGIN{ OFS=FS="\t"; while(getline<f) cand[$1][$2]++ }
  $2 in cand && $3 in cand[$2] { print $2,$3 }
  ' | sort | uniq -c | sort -nr
