#!/bin/bash

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

cat_dict "${lang1}" "${lang2}" "${pos}"> "${dict}"

if $precomp; then
    cat words/${dir}/precomp_${pos}.tsv >>"${dict}"
fi


# Break apart the input words, translate each part using ${dict}, the
# put them back together in all the various ways, with #-marks between
# the parts:
< words/${pos}.${lang1} ana ${lang1} \
    | grep -ve +Err/ -e +Der/ \
    | clean_cmp_ana ${lang1} ${pos} \
    | gawk -f uniq_ana.awk \
    | tee tmp/${dir}/${pos}_${suff}_ana_found \
    | gawk -v dict="${dict}" -f compound_translate.awk \
    | awk -F'\t' '$2' \
    > tmp/${dir}/${pos}_${suff}


# If noun, try generating +SgGenCmp+Cmp analyses and appending those:
if [[ ${pos} = N ]]; then
    # Generate genitives:
    <tmp/${dir}/${pos}_${suff} cut -f2- \
        | tr '\t' '\n' \
        | awk -F'#' 'NF==2{
                       sub(/.*\//,"",$1)
                       sub(/.*\//,"",$2)
                       print $1"+N+SgNomCmp+Cmp#"$2"+N+Sg+Nom"
                       print $1"+N+SgGenCmp+Cmp#"$2"+N+Sg+Nom"
                     }' \
                       | $LOOKUP $GTHOME/langs/${lang2}/src/generator-gt-norm.xfst \
                       | awk -F'#|\t' '
                     $3~/[äö-]/ || $0~/[+][?]$/{next} 
                     NF==3{sub(/[+].*/,"",$1);sub(/[+].*/,"",$2)}
                     $1$2!=$3{print $1"#"$2"\t"$3}' \
                         >tmp/${dir}/${pos}_${suff}_gen
    # Append genitives to the rest:
    <tmp/${dir}/${pos}_${suff} gawk \
        -v genf=tmp/${dir}/${pos}_${suff}_gen \
        'BEGIN{OFS=FS="\t"; while(getline<genf)gen[$1][$2]++}
         {
           print
           split($3, a, /[\/#]/)
           trglm = a[2]"#"a[4]
         }
         trglm in gen { 
           for(trg in gen[trglm]) print $1, trg, $3
         }' | sort -u >tmp/${dir}/${pos}_${suff}_withgen
else
    sort -u tmp/${dir}/${pos}_${suff} > tmp/${dir}/${pos}_${suff}_withgen
fi

# Filter out those candidates that are in the already existing
# translations, and extract the compound-part-pairs that created the
# good translations:
<tmp/${dir}/${pos}_${suff}_withgen gawk \
    -v dict=<(cat words/${dir}/${pos}.rev words/${dir}/${pos}.tsv) \
    'BEGIN{
       OFS=FS="\t"
       while(getline<dict) for(i=2;i<=NF;i++) if($i) d[$1"\t"$i]++
     }
     $1"\t"$2 in d{
       sub(/#/,"#\n",$3)
       print $3
     }' >tmp/${dir}/${pos}_${suff}_goodparts

# Now split candidates into those where both parts are in the
# "created-good-translations" file, or none, or only one
# (also, at this point we skip the non-fad words):
good=out/${dir}/${pos}_${suff}
bad=out/${dir}/${pos}_${suff}no
ugly=out/${dir}/${pos}_${suff}low
: > ${good}; : > ${bad}; : > ${ugly} # empty out the files since below awk appends
<tmp/${dir}/${pos}_${suff}_withgen gawk \
    -v fadf=fadwords/${pos}.${lang1} \
    -v fad_only=${FAD_ONLY} \
    -v goodparts=tmp/${dir}/${pos}_${suff}_goodparts \
    -v good=${good} \
    -v bad=${bad} \
    -v ugly=${ugly} \
    'BEGIN{
       FS="\t|#"
       OFS="\t"
       while(getline<fadf) fad[$0]++
       while(getline<goodparts) g[$0]++
     }
     fad_only=="true" && !($1 in fad) {
       next
     }
     {
       curf = bad
     }
     $3"#" in g || $4 in g {
       curf = ugly
     }
     $3"#" in g && $4 in g {
       curf = good
     }
     {
       print $1,$2,g[$3"#"],g[$4] >curf
     }'

found=$(<tmp/${dir}/${pos}_${suff}_ana_found wc -l)
ngood=$(cut -f1 ${good}|sort -u| wc -l)
nbad=$(cut  -f1 ${bad}|sort -u| wc -l)
nugly=$(cut -f1 ${ugly}|sort -u| wc -l)
echo "${pos} compound analyses found: ${found}, ${ngood} translated with both parts seen, ${nugly} one part seen, ${nbad} no parts seen ($suff)" >&2
