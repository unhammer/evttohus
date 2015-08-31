#!/bin/bash

#set -e -u
#cd "$(dirname "$0")"
source functions.sh

lang1=$1
lang2=$2
pos=$3


words-wanted () {
    cut -f1 words/${lang1}${lang2}/${pos}.tsv |
      sort -u |
      comm -23 fadwords/${pos}.${lang1} -
}

decomp () {
    local -r l=$1
    local -r p=$2
    ana ${l} |
    grep -ve +Err/ -e +Der/ |
    clean_cmp_ana ${l} ${p} |
    gawk -f uniq_ana.awk
}

catlexc () {
    local -r l=$1
    local -r p=$2
    case $p in
        N) poslexc=nouns;;
        V) poslexc=verbs;;
        A) poslexc=adjectives;;
        *) echo TODO >&2;return;;
    esac
    sed 's/!.*//' $GTHOME/langs/${l}/src/morphology/stems/${poslexc}.lexc |
      grep '^[^ ]*:[^ ]*  *[^ ]* *; *$' |
      sed 's/[+:#].*//'
}

l1-part-pairs () {
    cat <(catlexc ${lang1} ${pos}) words/${pos}.${lang1} |
      sort -u |
      decomp ${lang1} ${pos} |
      gawk -v want=<(words-wanted) -F'\t' 'BEGIN{while(getline<want)ws[$0]++} 
      $2 in ws{print "SUFF\t"$2"\t"$3} 
      $3 in ws{print "PREF\t"$3"\t"$2}'
}

l2-part-pairs () {
    cat_dict ${lang1} ${lang2} ${pos} |
    gawk -v pairs=<(l1-part-pairs) -F'\t' 'BEGIN{while(getline<pairs){if($1=="SUFF")s[$3]=$2;else p[$3]=$2}} 
    $1 in s{print "SUFF\t"$2"\t"s[$1]} 
    $1 in p{print "PREF\t"$2"\t"p[$1]}'
}

main () {
  cat <(catlexc ${lang2} ${pos}) words/${pos}.${lang2} |
    decomp ${lang2} ${pos} |
    gawk -f uniq_ana.awk |
    gawk -v max=5 -v pairs=<(l2-part-pairs) -F'\t' 'BEGIN{while(getline<pairs){if($1=="SUFF")s[$2][$3]++;else p[$2][$3]++}} 
    $3 in s{for(l1 in s[$3])hits[l1][$2]++} 
    $2 in p{for(l1 in p[$2])hits[l1][$3]++} 
    END{PROCINFO["sorted_in"]="@val_num_desc";  for(l1 in hits){n=0;for(l2 in hits[l1]){n++;if(n>max)break;print hits[l1][l2]"\t"l1"\t"l2}}}' 
}

main
