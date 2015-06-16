#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
nob=(   al   al    i   ikk   il  ell  ell   on   an  iker  iner  or   ur   ør   ær   ar   ater   or   as   tet  utt   ent   ant   iv     isk    alsk  isk )
sma=( aale aale  ija  ihke ïjle elle elle ovne aane ikere jnere ore uvre ööre æære aare aatere ovre aase teete uhte eente aante ijve ihkeles ihkeles eles )
pos=(    N    A    N     N    N    N    A    N    N     N     N   N    N    N    N    N      N    N    N     N    N     N     N    N       A       A    A )

for k in "${!nob[@]}"; do
    grep "..${nob[k]}$" words/${pos[k]}.nob \
    | sed "s/${nob[k]}$/${sma[k]}/" \
    | ana sma \
    | grep -v +Cmp | posgrep ${pos[k]} \
    | cut -f1 \
    | grep "${sma[k]}$" \
    | awk -v nob=${nob[k]} -F"${sma[k]}$" '{print $1 nob "\t" $0}'
done | sort -u
