#!/usr/bin/env awk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

BEGIN {
  OFS=FS="\t"
  f1="words-src-fad/"pos".sme"
  while(getline<f1) sme[$0]++;
  f2="words-src-fad/"pos".nob"
  while(getline<f2) nob[$0]++
}
$1 in nob{
  seennob[$1]++
}
$3 in sme{
  seensme[$3]++
}
$7 {
  seenana++
}
END {
  printf("%s\t%1.1f\t%6d\t%1.1f\t%6d\t%1.1f\n",
         FILENAME,
         length(seensme)/length(sme)*100, length(sme),
         length(seennob)/length(nob)*100, length(nob),
         seenana/(NR+0.000001)*100 )
}
