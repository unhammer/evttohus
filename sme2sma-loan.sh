#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
sme=(      ála  )
sma=(     aale  )
pos=(        A  )

for k in "${!sme[@]}"; do
    grep "..${sme[k]}$" words/${pos[k]}.sme \
    | sed "s/${sme[k]}$/${sma[k]}/" \
    | ana sma \
    | grep -v +Cmp | posgrep ${pos[k]} \
    | cut -f1 \
    | grep "${sma[k]}$" \
    | awk -v sme=${sme[k]} -F"${sma[k]}$" '{print $1 sme "\t" $0}'
done | sort -u
