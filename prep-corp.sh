#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

lang=$1

test -d freq || mkdir freq

echo "ccat ..."
ccat_all ${lang} | xz - >freq/plaincorp.${lang}.xz
echo "preprocess ..."
xzcat freq/plaincorp.${lang}.xz | preprocess ${lang} | xz - > freq/prepcorp.${lang}.xz
