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

# Split words into verbs and nonverbs:
cat <(cut -f1  words-src-fad/smenob/V*.tsv) \
    <(cut -f2- words-src-fad/nobsme/V*.tsv | tr '\t' '\n') \
    | sort -u > words-src-fad/V.sme
cat <(cut -f1  words-src-fad/smenob/[^V]*.tsv) \
    <(cut -f2- words-src-fad/nobsme/[^V]*.tsv | tr '\t' '\n') \
    | sort -u > words-src-fad/nonV.sme


# TODO: any point in lemmatising sme before smjifying? (should all be
# lemmatised already but who knows)
dir=smesmj
fsts=$GTHOME/words/dicts/${dir}
(
    cd ${fsts}/scripts
    make
)

test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

< words-src-fad/V.sme    lookup_good ${fsts}/scripts/sme2smj-verb.bin  > out/${dir}/V_xfst
< words-src-fad/nonV.sme lookup_good ${fsts}/scripts/sme2smj-nomen.bin > out/${dir}/nonV_xfst

cat words-src-fad/sme | lookup_good ${fsts}/bin/${dir}.fst >out/${dir}/all_lexc


# Just print some frequency stats:
test -d tmp || mkdir tmp
for t in lms forms; do
    for out in V_xfst nonV_xfst all_lexc; do
        join_freq out/${dir}/${out} freq/$t.smj > tmp/$t.belagt.${out}
    done
done
wc -l tmp/{lms,forms}.belagt.*
