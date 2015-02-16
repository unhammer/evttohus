#!/usr/bin/env awk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

### Ensure we have lines in the format
#nob	candidate	sme
### where candidate is in sma or smj

BEGIN {
  OFS=FS="\t"
  if(fromlang=="sme") {
    trgcol=1
    srctrg=smenob
    trgsrc=nobsme
  }
  else if(fromlang=="nob") {
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

!($1 in trans) {
  trans[$1]["?????"]++
}

{
  for(trg in trans[$1]) {
    if(trgcol==1) {
      print trg, $2, $1
    }
    else {
      print $1, $2, trg
    }
  }
}
