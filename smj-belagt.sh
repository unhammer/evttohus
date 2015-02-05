#!/bin/bash

noconvert=$1

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

test -d tmp || mkdir tmp

cd tmp


if [[ $# -ge 1 ]]; then
    echo "Converting corpora ..."
    for lang in smj sme; do 
        convert_all $lang
    done
else
    echo "Skipping corpus conversion ..."
fi
for lang in smj sme; do
    ccat_all $lang | xz - > corpus.$lang.xz
    xzcat *.$lang.xz | ana $lang | lemma_per_line | to_freqlist > lm-freqlist.$lang
    xzcat *.$lang.xz | poormans_tokeniser | to_freqlist > form-freqlist.$lang
done

xmlgrep_fad $GTHOME/words/dicts/smenob/src/V*.xml    >fad-verb.sme
xmlgrep_fad $GTHOME/words/dicts/smenob/src/[^V]*.xml >fad-nonverb.sme

# TODO: any point in lemmatising sme before smjifying? (should all be
# lemmatised already but who knows)
(
    cd $GTHOME/words/dicts/smesmj/scripts
    make
)
< fad-verb.sme    lookup_good $GTHOME/words/dicts/smesmj/scripts/sme2smj-verb.bin  >fad.sme.smjifisert-verb
< fad-nonverb.sme lookup_good $GTHOME/words/dicts/smesmj/scripts/sme2smj-nomen.bin >fad.sme.smjifisert-nonverb
cat fad-verb.sme fad-nonverb.sme \
    | lookup_good $GTHOME/words/dicts/smesmj/bin/smesmj.fst >fad.sme.smjifisert-ordbok


join_freq fad.sme.smjifisert-verb lm-freqlist.smj > lm-belagt-smjifisert-verb
join_freq fad.sme.smjifisert-nonverb lm-freqlist.smj > lm-belagt-smjifisert-nonverb
join_freq fad.sme.smjifisert-ordbok lm-freqlist.smj > lm-belagt-smjifisert-ordbok

join_freq fad.sme.smjifisert-verb form-freqlist.smj > form-belagt-smjifisert-verb
join_freq fad.sme.smjifisert-nonverb form-freqlist.smj > form-belagt-smjifisert-nonverb
join_freq fad.sme.smjifisert-ordbok form-freqlist.smj > form-belagt-smjifisert-ordbok

wc -l *belagt-smjifisert*
