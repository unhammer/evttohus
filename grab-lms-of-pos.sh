#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

lang=$1
pos=$2

test -d words || mkdir words

all_lms_of_pos ${lang} ${pos} > words/${lang}.${pos}
