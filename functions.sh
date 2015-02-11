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

freq_annotate () {
    # Look up a column ($1) of candidates from stdin in freqfile ($2)
    # and append the freq to each line of the candidates.
    # sum is the sum of freqs, norm is the sum of a freqfile.
    awk -v column="$1" -v freqs="$2" -v sum="$3" -v norm="$4" '
BEGIN{
  OFS=FS="\t"
  while(getline<freqs)freq[$2]=$1
}
function ceil(xs) {
  x = sprintf("%d", xs)
  return (x == int(x)) ? x : int(x)+1 
}
{
  print $0,ceil(freq[$column]*norm/sum)
}'
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


dict_xml2tsv () {
    restriction=$1
    shift
    # forall e where $restriction
    #   print lg/l/text
    #   forall mg/tg/t:
    #     print text()
    #   print "\n"
    xmlstarlet sel -t \
        -m "//e${restriction}" -c './lg/l/text()' \
        -m './mg/tg/t' -o $'\t' -c './text()' \
        -b -n \
        "$@"
}

dir2tsv () {
    # Will output into "$dir" under cwd
    restriction=$1
    dir=$2
    test -d $dir || mkdir $dir
    for xml in $GTHOME/words/dicts/$dir/src/*.xml; do
        tsv=$dir/$(basename "$xml")
        tsv=${tsv%%.xml}.tsv
        if ! dict_xml2tsv "${restriction}" "${xml}" > "${tsv}"; then
            # No hits for that file:
            test -s "${tsv}" || rm -f "${tsv}"
        fi
    done
}

dicts2tsv () {
    restriction=$1
    shift
    for lang1 in "$@"; do
        for lang2 in "$@"; do
            dir=${lang1}${lang2}
            if [[ $lang1 = $lang2 ]]; then
                continue
            elif [[ ! -d $GTHOME/words/dicts/$dir/src ]]; then
                echo "\$GTHOME/words/dicts/$dir doesn't exist (yet)" >&2
                continue
            else
                dir2tsv "${restriction}" "${dir}"
            fi
        done
    done

    for lang in "$@"; do
        cat <(cut -f1  ${lang}???/*.tsv) \
            <(cut -f2- ???${lang}/*.tsv | tr '\t' '\n') \
            | sort -u > ${lang}
    done
}
