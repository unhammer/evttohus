#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

test -d words || mkdir words

for lang in smj sma; do
    for pos in V N A; do
        all_lms_of_pos ${lang} ${pos} > words/${lang}.${pos}
    done
done
