#!/bin/bash

### Grab the text-parts of a toktmx file, and print like
#lang1	text1a
#lang2	text2a
#
#lang1	text1b
#lang2	text2b
#
### etc.

set -e -u

lang1=$1
lang2=$2
file=$3

xmlstarlet sel -t \
    -m "//tu" \
    -o "${lang1}	" -v "./tuv[@xml:lang='${lang1}']/seg/text()" -n \
    -o "${lang2}	" -v "./tuv[@xml:lang='${lang2}']/seg/text()" -n \
    -n \
    "${file}" \
    | awk '
BEGIN{
  OFS=FS="\t"
}
{
  # Make sure there is only one tab in each line:
  line=$1"\t"
  for(i=2;i<=NF;i++)line=line $i
  $0=line
}
{
  # Trim:
  sub(/^ *| *$/,"",$2)
  print
}'
