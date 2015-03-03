#!/bin/bash

set -e -u

source $(dirname $0)/../functions.sh

lang=$1

grep "^<s xml:lang=\"${lang}\"" | ana ${lang} --xml | ana_to_lemmas
