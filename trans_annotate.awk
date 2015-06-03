#!/usr/bin/env awk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

### Ensure we have lines in the format
#nob	candidate	sme
### where candidate is in sma or smj

BEGIN {
  OFS=FS="\t"
  if(fromlang=="sme") {
    srctrg=smenob
    trgsrc=nobsme
  }
  else if(fromlang=="nob") {
    srctrg=nobsme
    trgsrc=smenob
  }
  else {
    print "ERROR: unknown fromlang: ", fromlang >"/dev/stderr"
  }
  while(getline<srctrg) {
    for(i=2;i<=NF;i++) {
      trans[$1][$i]++
    }
  }
  while(getline<trgsrc) {
    for(i=2;i<=NF;i++) {
      trans[$i][$1]++
    }
  }
}

!($1 in trans) {
  trans[$1]["?????"]++
}

fromlang=="nob" {               # nob is src
  for(trg in trans[$1]) {
    out[trg][$2][$1]++
  }
}
fromlang=="sme" {               # nob is trg
  for(trg in trans[$1]) {
    out[$1][$2][trg]++
  }
}

END {
  # for apertium-sme-sma, sme is column 1
  for(sme in out){
    for(cand in out[sme]){
      nobjoined=""
      for(nob in out[sme][cand]) {
        nobjoined=nob"/"nobjoined
      }
      sub(/\/$/, "", nobjoined)
      print sme,cand,nobjoined
    }
  }
} 
