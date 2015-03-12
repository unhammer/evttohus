#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
nob=(     itet      i     og      é      e      et      ek     ol     em     om    ør  ie )
smj=( itiehtta  iddja  åvggå  iedja  iedja  iehtta  iehkka  åvllå  iebma  åvmmå  erra  ij )
pos=(        N      N      N      N      N       N       N      N      N      N     N   N )

for k in "${!nob[@]}"; do
    grep "..${nob[k]}$" fadwords/${pos[k]}.nob \
        | sed "s/${nob[k]}$/${smj[k]}/" \
        | ana smj \
        | grep -v +Cmp | posgrep ${pos[k]} \
        | cut -f1 \
        | grep "${smj[k]}$" \
        | awk -v nob=${nob[k]} -F"${smj[k]}$" '{print $1 nob "\t" $0}'
done
