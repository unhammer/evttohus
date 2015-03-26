#!/bin/bash

# Restrict to words with src=fad:
words=fadwords
# Uncomment to try on all words:
#words=words

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
lang1=${dir%???}
lang2=${dir#???}
pos=$2
if [[ $# -eq 3 ]]; then
    precomp=true
    suff=precomp
else
    precomp=false
    suff=decomp
fi

dict=tmp/${dir}/${pos}_${suff}.dict

maindict=words/${dir}/${pos}.tsv
if [[ ! -f ${maindict} ]]; then
    echo "${maindict} doesn't exist"
    exit 1
else
    cat "${maindict}" > "${dict}"
fi

revdict=words/${lang2}${lang1}/${pos}.tsv
if [[ -f ${revdict} ]]; then
    <"${revdict}" awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $i,$1}' >>"${dict}"
fi
if $precomp; then
    cat words/${dir}/precomp_${pos}.tsv >>"${dict}"
fi

echo -n "${pos} compound analyses found: " >&2
< ${words}/${pos}.${lang1} ana ${lang1} \
    | grep -v +Err/ \
    | clean_cmp_ana ${lang1} ${pos} \
    | gawk -f uniq_ana.awk \
    | tee >(wc -l >&2) \
    | gawk -v dict="${dict}" -f compound_translate.awk \
    | awk -F'\t' '$2' \
    > tmp/${dir}/${pos}_${suff}

if [[ ${pos} = N ]]; then
  # There may be alternative ways of compounding (e.g. genitives), so
  # try the generator:
  <tmp/${dir}/${pos}_${suff} cut -f2- \
      | tr '\t' '\n' \
      | awk -F'#' 'NF==2{
                     print $1"+N+SgNomCmp+Cmp#"$2"+N+Sg+Nom"
                     print $1"+N+SgGenCmp+Cmp#"$2"+N+Sg+Nom"
                   }' \
      | $LOOKUP $GTHOME/langs/${lang2}/src/generator-gt-norm.xfst \
      | awk -F'#|\t' '$3~/[äö-]/ || $0~/[+][?]$/{next} 
                      NF==3{sub(/[+].*/,"",$1);sub(/[+].*/,"",$2)}
                      $1$2!=$3{print $1"#"$2"\t"$3}' \
      >tmp/${dir}/${pos}_${suff}_gen
else
  touch tmp/${dir}/${pos}_${suff}_gen
fi

<tmp/${dir}/${pos}_${suff} gawk \
    -v genf=tmp/${dir}/${pos}_${suff}_gen \
    'BEGIN{OFS=FS="\t"; while(getline<genf)gen[$1][$2]++}
     $2 in gen { 
       for(trg in gen[$2]) print $1, trg
     }
     {
       gsub(/#/,"",$2)
       print $1, $2
     }' >out/${dir}/${pos}_${suff}

echo -n "${pos} compounds translated:    " >&2
grep -v '^#' out/${dir}/${pos}_${suff}|cut -f1|sort -u| wc -l >&2
