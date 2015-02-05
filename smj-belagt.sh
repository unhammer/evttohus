#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh
trap 'kill 0' EXIT

./dicts-to-tsv.sh

if [[ $# -ge 1 ]]; then
    shift
    for lang in smj sme; do
        ./make-freq.sh $lang "$@"
    done
fi

test -d tmp || mkdir tmp
cd tmp

cat <(cut -f1  ../words-src-fad/smenob/V*.tsv) \
    <(cut -f2- ../words-src-fad/nobsme/V*.tsv | tr '\t' '\n') \
    | sort -u > verb.sme
cat <(cut -f1  ../words-src-fad/smenob/[^V]*.tsv) \
    <(cut -f2- ../words-src-fad/nobsme/[^V]*.tsv | tr '\t' '\n') \
    | sort -u > nonverb.sme

# TODO: any point in lemmatising sme before smjifying? (should all be
# lemmatised already but who knows)
(
    cd $GTHOME/words/dicts/smesmj/scripts
    make
)
< verb.sme    lookup_good $GTHOME/words/dicts/smesmj/scripts/sme2smj-verb.bin  >sme.smjifisert-verb
< nonverb.sme lookup_good $GTHOME/words/dicts/smesmj/scripts/sme2smj-nomen.bin >sme.smjifisert-nonverb
cat verb.sme nonverb.sme \
    | lookup_good $GTHOME/words/dicts/smesmj/bin/smesmj.fst >sme.smjifisert-ordbok


for t in lms forms; do
    for fst in verb nonverb ordbok; do
        join_freq sme.smjifisert-$fst ../freq/$t.smj > $t-belagt-smjifisert-$fst
    done
done

wc -l *-belagt-smjifisert-*
