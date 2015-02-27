#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

BEGIN {
  FS=OFS="\t"

  while(getline < srcf) {
    parts=""
    for(i=2;i<=NF;i++) {
      parts=parts"\t"$i
    }
    sub(/^\t/,"",parts)
    src[$1][parts]++
  }
  while(getline < trgf) {
    parts=""
    for(i=2;i<=NF;i++) {
      parts=parts"\t"$i
    }
    sub(/^\t/,"",parts)
    trg[$1][parts]++
  }
}


$1 in src {
  for(i=2;i<=NF;i++) {
    if($i in trg) {
      for(sp in src[$1]) {
        for(tp in trg[$i]) {
          #print $1,$i,sp,tp
          print $1,sp
        }
      }
    }
  }
}
