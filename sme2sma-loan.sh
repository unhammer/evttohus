#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

# divvun.no runs an old version of bash, so we use a plain array where keys have to match up:
src=(   al  ála  iija ihkka iila ealle šuvdna iovdna ovdna  ána ihkar uvra evra    alaš alaš eanta tehta uhta )
trg=( aale aale   ija  ihke ïjle  elle sjovne  jovne  ovne aane ikere uvre ööre ihkeles eles eente teete uhte )
pos=(    N    A     N     N    N     N      N      N     N    N     N    N    N       A    A     N     N    N )

loans sme sma "$1"
