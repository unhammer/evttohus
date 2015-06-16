#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
sme=(   al  ála  iija ihkka iila ealle šuvdna iovdna ovdna  ána ihkar uvra evra    alaš alaš eanta tehta uhta )
sma=( aale aale   ija  ihke ïjle  elle sjovne  jovne  ovne aane ikere uvre ööre ihkeles eles eente teete uhte )
pos=(    N    A     N     N    N     N      N      N     N    N     N    N    N       A    A     N     N    N )

for k in "${!sme[@]}"; do
    grep "..${sme[k]}$" words/${pos[k]}.sme \
    | sed "s/${sme[k]}$/${sma[k]}/" \
    | ana sma \
    | grep -v +Cmp | posgrep ${pos[k]} \
    | cut -f1 \
    | grep "${sma[k]}$" \
    | awk -v sme=${sme[k]} -F"${sma[k]}$" '{print $1 sme "\t" $0}'
done | sort -u
