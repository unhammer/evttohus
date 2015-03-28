#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

### Call like

# gawk -v srcf=nob.cmps -v trgf=sma.cmps -f precomp.awk words/nobsma/N_nobsma.tsv

### where the .cmps have a form (from words/nobsma/N_nobsma) in the
### first column, and compound parts in the following columns, ie. the
### output of clean_cmp_ana.

BEGIN {
  FS=OFS="\t"

  while(getline < srcf) {
    if(NF==3) {
      src1[$1][$2]++
      src2[$1][$3]++
    }
    else if(NF==4) {
      # Treat three-parts as two alternative two-parts:
      src1[$1][$2]++
      src2[$1][$3$4]++
      src1[$1][$2$3]++
      src2[$1][$4]++
    }
    # Anything longer unlikely to be good.
  }
  while(getline < trgf) {
    if(NF==3) {
      trg1[$1][$2]++
      trg2[$1][$3]++
    }
    else if(NF==4) {
      # Treat three-parts as two alternative two-parts:
      trg1[$1][$2]++
      trg2[$1][$3$4]++
      trg1[$1][$2$3]++
      trg2[$1][$4]++
    }
    # Anything longer unlikely to be good.
  }
}

function print_pairs(s, t) {
  for(sp1 in src1[s]) {
    for(tp1 in trg1[t]) {
      print sp1,tp1
    }
  }
  for(sp2 in src2[s]) {
    for(tp2 in trg2[t]) {
      print sp2,tp2
    }
  }
}

$1 in src1 {
  for(i=2;i<=NF;i++) {
    if($i in trg1) {
      print_pairs($1,$i)
    }
  }
}
