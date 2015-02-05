#!/bin/bash

ana () {
    lang=$1
    $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/${lang}/tools/preprocess/abbr.txt \
        |lookup -q $GTHOME/langs/${lang}/src/analyser-gt-desc.xfst
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

poormans_tokeniser () {
    sed "s/[…““’]/'/g" | tr $' ;/\\0123456789{}[]«»"_.?:-:,)(””!¶\t'"'" '\n'
}

join_freq () {
    smjifisert=$1
    freqs=$2
    LC_ALL=C join -t$'\t' -j2 <(LC_ALL=C sort -k2,2 -t$'\t' "${smjifisert}" ) <(LC_ALL=C sort -k2,2 -t$'\t' "${freqs}")
}

xmlgrep_fad () {
    xmlstarlet sel -t -m '//e[@src="fad"]/lg/l/text()' -c . -n "$@"
}

test -d tmp || mkdir tmp

for lang in smj sme; do
    convert2xml $GTBOUND/orig/$lang
    ccat -a -l $lang $GTBOUND/converted/$lang |xz - >tmp/bound.$lang.xz
    convert2xml $GTFREE/orig/$lang
    ccat -a -l $lang $GTFREE/converted/$lang |xz - >tmp/free.$lang.xz
    # assuming we now have tmp/{free,bound,big}.$lang.xz
    xzcat tmp/*.$lang.xz | ana $lang | lemma_per_line | to_freqlist > tmp/lm-freqlist.$lang
    xzcat tmp/*.$lang.xz | poormans_tokeniser | to_freqlist > tmp/form-freqlist.$lang
done

xmlgrep_fad $GTHOME/words/dicts/smenob/src/V*.xml >tmp/fad-verb.sme
xmlgrep_fad $GTHOME/words/dicts/smenob/src/[^V]*.xml >tmp/fad-nonverb.sme

# TODO: any point in lemmatising sme before smjifying? (should all be
# lemmatised already but who knows)
(
    cd $GTHOME/words/dicts/smesmj/scripts
    make
    < tmp/fad-verb.sme lookup -q sme2smj-verb.bin |grep -v '+?$' |grep . >tmp/fad.sme.smjifisert-verb
    < tmp/fad-nonverb.sme lookup -q sme2smj-nomen.bin |grep -v '+?$' |grep . >tmp/fad.sme.smjifisert-nonverb
)

cat tmp/fad-*.sme| lookup -q $GTHOME/words/dicts/smesmj/bin/smesmj.fst |grep -v '+?$' |grep . >tmp/fad.sme.smjifisert-ordbok

join_freq tmp/fad.sme.smjifisert-verb tmp/lm-freqlist.smj > tmp/lm-belagt-smjifisert-verb
join_freq tmp/fad.sme.smjifisert-nonverb tmp/lm-freqlist.smj > tmp/lm-belagt-smjifisert-nonverb
join_freq tmp/fad.sme.smjifisert-ordbok tmp/lm-freqlist.smj > tmp/lm-belagt-smjifisert-ordbok

join_freq tmp/fad.sme.smjifisert-verb tmp/form-freqlist.smj > tmp/form-belagt-smjifisert-verb
join_freq tmp/fad.sme.smjifisert-nonverb tmp/form-freqlist.smj > tmp/form-belagt-smjifisert-nonverb
join_freq tmp/fad.sme.smjifisert-ordbok tmp/form-freqlist.smj > tmp/form-belagt-smjifisert-ordbok

wc -l tmp/*belagt-smjifisert*
