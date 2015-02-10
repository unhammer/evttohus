#!/bin/bash

set -e -u

# Restrict to words with src=fad:
words=words-src-fad
# Uncomment to try on all words:
#words=words

source functions.sh
lang1=$1
lang2=$2
dir=${lang1}${lang2}

clean_ana () {
    lang=$1
    if [[ ${lang} = nob ]]; then
        # nob for some reason has completely different analysis format :(
        grep "#+Cmp.*+${pos}[^#]*$" \
            | sed 's/+X+N/+N/g' \
            | sed 's/+[^#+]*#+CmpS*+/	/g;
                   s/+[^#+]*#+CmpS*-/-	/g;
                   s/+[^#]*$//' \
            | sed 's/		*/	/g'
        # samarbeidsspørsmål	samarbeid	+N#+CmpS+spørs+X+N#+Cmp+mål+N+Neu+Pl+Indef
        # forsøksråd	for	+N#+Cmp+søk+N#+CmpS+råd+N+Neu+Sg+Indef
        # primærprodukt	primær+A#+Cmp+produkt+N+Neu+Sg+Indef
        # kjerneområde	kjerne	+N#+Cmp+område+N+Neu+Sg+Indef
        # kystfiskerlag	kystfisker	+N#+Cmp+lag+N+Neu+Pl+Indef
    else
        grep "+Cmp#.*+${pos}[^#]*$" \
            | sed 's/+[^#]*#*/	/g;s/	$//'
    fi
}

test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

for pos in N V A; do
    dict=words/${dir}/${pos}_${dir}.tsv
    if [[ ! -f ${dict} ]]; then echo "${dict} doesn't exist"; continue; fi
    echo -n "${pos} compound analyses found: " >&2
    cat <(cut -f1  ${words}/${lang1}???/${pos}_*.tsv) \
        <(cut -f2- ${words}/???${lang1}/${pos}_*.tsv | tr '\t' '\n') \
        | sort -u \
        | ana ${lang1} \
        | clean_ana ${lang1} \
        | gawk -f uniq_ana.awk \
        | tee >(wc -l >&2) \
        | gawk -vdict=${dict} -f compound_translate.awk \
        > out/${dir}/${pos}_decomp
    echo -n "${pos} compounds translated:    " >&2
    grep -v '^#' out/${dir}/${pos}_decomp | wc -l >&2
done
