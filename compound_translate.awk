#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

## Run like:

# gawk -vdict=words/smesmj/N_smesmj.tsv compound-translate.awk < N_decompounded.sme

## where words/smesmj/N_smesmj.tsv has sme in the first column and smj
## in the following columns (there may be more than one
## smj-translation per sme-word), and N_decompounded.sme has one
## compound analysis per line, with the sme form in the first column,
## followed by compound parts.

BEGIN {
  FS=OFS="\t"
  while(getline < dict) {
    for(i=2;i<=NF;i++) {
      trans[$1][$i]++
    }
  }
}

function del_ar(ar) {
  for(i in ar) {
    delete ar[i]
  }
}

function asplit(string, assoc_ar, sep) {
  # Like split, but results go in an associative array, order-uniqueness gone
  split(string, asplit_tmp, "\t");
  del_ar(assoc_ar)
  for(i in asplit_tmp) {
    assoc_ar[asplit_tmp[i]]++
  }
}

function combine(cand, i) {
  # The first index of cand is the position in the compound word, the
  # second is the list of possible translations of that position. Say
  # we have:
  # cand[1][a], cand[2][b], cand[2][ß], cand[3][c], cand[3][ć],
  # then we want to return all the possibilities abc, aßc, abs, aßć.
  if(!(i in cand)) {
    return "\t"
  }
  suffixes_s = combine(cand, i+1)
  asplit(suffixes_s, suffixes, "\t")
  withthis=""
  for(part in cand[i]) {
    for(suf in suffixes) {
      withthis = withthis part suf "\t"
    }
  }
  sub(/\t$/,"", withthis)
  return withthis
}

$1 in trans {
  trgs = ""
  for(trg in trans[$1]) {
    trgs = trg", "trgs
  }
  sub(/, $/, "", trgs)
  printf "# %s in %s as %s\n", $1, dict, trgs
}

# TODO: could try to look up three-part compounds by their two-part
# combinations, e.g. a word split into a,b,c might get candidates from
# looking up ab,c or a,bc

{
  del_ar(cand)
  good=1
  for(i=2; i<=NF; i++) {
    src=$i
    srcnodash=$i; sub(/-$/, "", srcnodash)
    if(src in trans) {
      for(trg in trans[src]) {
        cand[i-1][trg]++
      }
    }
    else if(srcnodash in trans) {
      for(trg in trans[srcnodash]) {  # look up without dash,
        cand[i-1][trg"-"]++           # then re-add dash to result
      }
    }
    else {
      good=0
    }
  }
  if(good==1) {
    print $1, combine(cand, 1)
  }
}
