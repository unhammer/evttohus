#!/bin/bash

lookup_good () {
    fst=$1
    lookup -q "${fst}" | grep -v '+?$' |grep .
}

preprocess () {
    lang=$1
    $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/${lang}/tools/preprocess/abbr.txt
}

ana () {
    lang=$1
    preprocess $lang | lookup -q $GTHOME/langs/${lang}/src/analyser-gt-desc.xfst
}

lemma_per_line () {
    # Note: if a form is ambiguous, it gets an unnaturally high lemma
    # "corpus count", but there's not really any simple way around
    # this, and we're not really after absolute corpus counts either
    # (this is more for comparing progress and whether something
    # exists at all)
    awk -F'\t' '/^$/{for(i in a)if(i)print i; for(i in a)delete a[i]} {sub(/\+.*/,"",$2);a[$2]++}'
}

to_freqlist () {
    sort|uniq -c|sort -nr|sed $'s/^ *//;s/ /\t/'
}

clean_punct () {
    sed "s/[…““’]/'/g" | tr $' ;/\\0123456789{}[]«»"_.?:-:,)(””!¶\t'"'" ' '
}

join_freq () {
    # Join two tsv lists by their second column
    freq1=$1
    freq2=$2
    (
        LC_ALL=C
        join -t$'\t' -j2 \
             <(sort -k2,2 -t$'\t' "${freq1}" ) \
             <(sort -k2,2 -t$'\t' "${freq2}")
    )
}

xmlgrep_fad () {
    xmlstarlet sel -t -m '//e[@src="fad"]/lg/l/text()' -c . -n "$@"
}

convert_all () {
    lang=$1
    convert2xml $GTBOUND/orig/$lang & P1=$!
    convert2xml $GTFREE/orig/$lang & P2=$!
    wait $P1 $P2
}

ccat_all () {
    lang=$1
    cat <(ccat -a -l $lang $GTBOUND/converted/$lang) \
        <(ccat -a -l $lang $GTFREE/converted/$lang)
}
