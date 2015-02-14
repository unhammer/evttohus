#!/bin/bash

find toktmx/sma2nob -type f -name '*.toktmx' \
    | xargs -n1 rogganreaiddut/toktmx-readable.sh \
    | awk '
BEGIN{
  OFS=FS="\t"
}
// {
  # Make sure there is only one tab in the line:
  line=$1"\t"
  for(i=2;i<=NF;i++)line=line $i
  $0=line
  sub(/^ *| *$/,"",$2)
}
$1=="sma" {
  sl=length($2);sma=$2;
}
$1=="nob" {
  nl=length($2);nob=$2;
  ld=nl-sl; if(ld<0){ ld=-ld }
}

/^nob/ && ld<30 && nl>5 && sl>5 && sma!=nob {
  print "sma",sma; print "nob",nob; print ""
}
'
