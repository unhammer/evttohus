#!/bin/bash

if [[ -n $LOOKUP && $LOOKUP != "lookup -q -flags mbTT" ]]; then
        echo "Warning: overriding strange value of LOOKUP: $LOOKUP"
fi
export LOOKUP="lookup -q -flags mbTT"

rev () {
    # /usr/bin/rev doesn't handle unicode. wonderful.
    perl -wlnpe '$_=reverse($_)'
}

lookup_good () {
    fst=$1
    $LOOKUP "${fst}" | grep -v '+?$' |grep .
}

preproc () {
    lang=$1
    shift
    $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/${lang}/tools/preprocess/abbr.txt "$@"
}

ana () {
    lang=$1
    shift
    preproc ${lang} "$@" | $LOOKUP $GTHOME/langs/${lang}/src/analyser-gt-desc.xfst
}

lemma_per_line () {
    # Used by make-freq.sh
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


clean_cmp_ana () {
    # Grep for compound analyses of a certain part of speech, and turn
    # output of lookup into tab-separated form followed by compound
    # lemmas
    lang=$1
    pos=$2
    if [[ ${lang} = nob ]]; then
        # nob for some reason has completely different analysis format :(
        grep "#+Cmp.*+${pos}[^#]*$" \
            | sed 's/+X+N/+N/g;s/+Nynorsk+N/+N/g' \
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
            | sed 's/+[^#]*#*/	/g' \
            | sed 's/		*/	/g' \
            | sed 's/	$//'
    fi
}

ana_to_lemmas () {
    perl -wnpe '# nob analyser:
                s/\+(X|Nynorsk)\+N/+N/g;
                s/\+[^#+\n]*#\+CmpS*\+/\t/g;
                s/\+[^#+\n]*#\+CmpS*-/-\t/g;
                s/\+[^#\n]*$//;
                # all other analysers:
                s/\+[^#\n]*#*/\t/g;
                s/\t+/\t/g; 
                s/\t$//'
}


xmlgrep_fad () {
    xmlstarlet sel -t -m '//e[@src="fad"]/lg/l/text()' -c . -n "$@"
}

convert_all () {
    lang=$1
    if [[ -n $GTBOUND ]]; then
        convert2xml $GTBOUND/orig/$lang & P1=$!
    else
        echo "GTBOUND not set, only converting GTFREE"
    fi
    convert2xml $GTFREE/orig/$lang & P2=$!
    wait $P1 $P2
}

ccat_all () {
    lang=$1
    if [[ -n $GTBOUND ]]; then
        cat <(ccat -a -l $lang $GTBOUND/converted/$lang) \
            <(ccat -a -l $lang $GTFREE/converted/$lang)
    else
        echo "GTBOUND not set, only ccat-ing GTFREE"
        ccat -a -l $lang $GTFREE/converted/$lang
    fi
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

mono_from_bi () {
    # Use translations
    lang=$1
    pos=$2
    cat <(cut -f1  ${lang}???/${pos}*.tsv) \
        <(cut -f2- ???${lang}/${pos}*.tsv | tr '\t' '\n') \
        | sort -u
}

dicts2tsv () {
    # Makes all pairings of the langs args.
    # Outputs to cwd (e.g. words or words-src-fad).
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
        mono_from_bi ${lang} "" > ${lang}
    done
}

lexc2lms () {
    # ugly hack to grep some lemmas out of lexc's
    sed 's/!.*//' \
        | grep -v '^[;   ]*[@+-:<]' \
        | grep ':.* .*;' \
        | sed 's/[:+].*//' \
        | tr -d '#%' \
        | sed 's/^ *//'
}

all_lms_of_pos () {
    lang=$1
    pos=$2
    lexc2lms < $GTHOME/langs/${lang}/src/morphology/lexicon.lexc \
        | cat - words/${lang} <(cut -f2 freq/forms.${lang}) \
        | sort -u \
        | ana ${lang} \
        | grep "+${pos}+[^#]*$" \
        | cut -f1 \
        | LC_ALL=C sort -u
}
