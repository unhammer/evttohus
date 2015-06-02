#!/usr/bin/env awk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

### Ensure we have lines in the format
#nob	candidate	sme
### where candidate is in sma or smj

BEGIN {
  OFS=FS="\t"
  if(fromlang=="sme") {
    srccol=3
    trgcol=1
    srctrg=smenob
    trgsrc=nobsme
  }
  else if(fromlang=="nob") {
    srccol=1
    trgcol=3
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

!($srccol in trans) {
  trans[$srccol]["?????"]++
}

# No /-joining the sme for apertium-sme-sma; all sme words here come
# via nob, but we want to be looking at the sme as the "source" in the
# final output, ie. we don't want them /-grouped.

# Instead, /-group the nob column:
fromlang=="nob" {               # nob is src
  for(trg in trans[$srccol]) {
    out[trg][$2][$srccol]++
  }
}
fromlang=="sme" {               # nob is trg
  for(trg in trans[$srccol]) {
    out[$srccol][$2][trg]++
  }
}

END {
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
