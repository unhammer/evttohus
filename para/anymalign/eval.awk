#!/usr/bin/gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

BEGIN {
  OFS=FS="\t"
  while(getline<srclmf) srclm[$1][$2]++
  while(getline<trglmf) trglm[$1][$2]++
  while(getline<transf) {
    srclm[$1]["*"]=1
    trglm[$2]["*"]=1
    for(s in srclm[$1]) for(t in trglm[$2]) trans[s][t]++
  }
  # Here we're only interested in whether a lemma/form is in fad at
  # all:
  while(getline<fadlmf) {
    fad[$1]=1
    fad[$2]=1
  }
}

{
  if(!($1 in srclm))srclm[$1]["*"$1]=1
  if(!($2 in trglm))trglm[$2]["*"$2]=1

  for(s in srclm[$1]) {
    for(t in trglm[$2]) {

      seen[s][t] += srclm[$1][s] + trglm[$2][t]
      freq[s][t] = $NF
      if(s in trans && t in trans[s]) {
        good[s][t]++
      }
      else {
        good[s][t]=0
      }

    }
  }
}

END {
  for(s in seen) {
    if(s in fad) {
      infad="fad"
    }
    else {
      infad=""
    }
    for(t in seen[s]) {
      if(s!="*" && t!="*") {
        print freq[s][t], seen[s][t], good[s][t], infad, s, t
      }
    }
  }

  truepos=0                     # where trans[s][t] and seen[s][t]
  missing=0                     # where trans[s][t] and seen[s] but not seen[s][t]
  falsepos=0                     # where seen[s][t] and but not trans[s][t]
  for(s in trans) {
    if(s=="*")continue
    for(t in trans[s]) {
      if(t=="*")continue
      if(s in seen) {
        if(t in seen[s]) truepos++
        else missing++
      }
    }
    if(s in seen) {
      if(s~"^[*]") {
        continue
      }
      for(t in seen[s]) {
        if(t~"^[*]") {
          continue
        }
        if(!(t in trans[s])) falsepos++
        #else truepos
      }
    }
  }
  print "# "truepos," good hits – translation pair in both gold and res"
  print "# "missing," coverage problems – pair in gold, but target missing from res"
  print "# "falsepos," false hits – pair in res, but target not in gold"

  fadmiss=0
  fadhit=0
  for(s in fad) {
    if(s in seen) {
      fadhit++
    }
    else {
      fadmiss++
    }
  }
  print "# "fadhit," fad covered – translation source in fad had candidate in res"
  print "# "fadmiss," fad missing – translation source in fad was missing from res"
}
