#!/bin/bash

set -e -u

source $(dirname $0)/../functions.sh

candidates=$1
lemmapair_ids=$2
# ^ from join-lemmas-on-ids.sh
fromfield=$3

<"${lemmapair_ids}" gawk \
    -v fromfield=${fromfield} \
    -v f=$candidates '
  BEGIN{ OFS=FS="\t"; while(getline<f) cand[$fromfield][$2]++ }
  $2 in cand && $3 in cand[$2] { print $2,$3 }
  ' | to_freqlist
