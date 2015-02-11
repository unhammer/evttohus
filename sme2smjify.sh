#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

./dicts-to-tsv.sh

if [[ $# -ge 1 ]]; then
    shift
    for lang in smj sme; do
        ./make-freq.sh $lang "$@"
    done
fi

# Split words into verbs and nonverbs:
for pos in V N A; do
    cat <(cut -f1  words-src-fad/smenob/${pos}*.tsv) \
        <(cut -f2- words-src-fad/nobsme/${pos}*.tsv | tr '\t' '\n') \
        | sort -u > words-src-fad/${pos}.sme
done
cat <(cut -f1  words-src-fad/smenob/[^VNA]*.tsv) \
    <(cut -f2- words-src-fad/nobsme/[^VNA]*.tsv | tr '\t' '\n') \
    | sort -u > words-src-fad/nonVNA.sme


# TODO: any point in lemmatising sme before smjifying? (should all be
# lemmatised already but who knows)
dir=smesmj
fsts=$GTHOME/words/dicts/${dir}
(
    cd ${fsts}/scripts && make
    cd ${fsts}/src && make
)

test -d out || mkdir out
test -d out/${dir} || mkdir out/${dir}

for pos in V N A nonVNA; do
    if [[ ${pos} = V ]]; then
        fstpos=sme2smj-verb.bin
    else
        fstpos=sme2smj-nomen.bin
    fi
    < words-src-fad/${pos}.sme lookup_good ${fsts}/scripts/${fstpos} > out/${dir}/${pos}_xfst
    < words-src-fad/${pos}.sme lookup_good ${fsts}/bin/${dir}.fst    > out/${dir}/${pos}_lexc
done


# Just print some frequency stats:
test -d tmp || mkdir tmp
for t in lms forms; do
    for out in out/${dir}/*_{xfst,lexc}; do
        join_freq ${out} freq/$t.smj > tmp/$t.belagt.$(basename ${out})
    done
done
wc -l tmp/{lms,forms}.belagt.*
