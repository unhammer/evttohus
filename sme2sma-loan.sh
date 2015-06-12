#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
nob=(       al  )
sme=(      ála  )
sma=(     aale  )
pos=(        A  )

for k in "${!nob[@]}"; do
    grep "..${nob[k]}$" words/${pos[k]}.nob \
        | sed "s/${nob[k]}$/${sma[k]}/" \
        | ana sma \
        | grep -v +Cmp | posgrep ${pos[k]} \
        | cut -f1 \
        | grep "${sma[k]}$" \
        | awk -v nob=${nob[k]} -F"${sma[k]}$" '{print $1 nob "\t" $0}'
done
