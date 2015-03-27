#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

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
    if [[ ${pos} = nonVNA ]]; then
        fstpos=sme2smj-N.bin
    else
        fstpos=sme2smj-${pos}.bin
    fi
    < fadwords/${pos}.sme lookup_good ${fsts}/scripts/${fstpos} > out/${dir}/${pos}_xfst
    < fadwords/${pos}.sme lookup_good ${fsts}/bin/${dir}.fst    > out/${dir}/${pos}_lexc
done


# Just print some frequency stats:
# test -d tmp || mkdir tmp
# for t in lms forms; do
#     for out in out/${dir}/*_{xfst,lexc}; do
#         join_freq ${out} freq/$t.smj > tmp/$t.belagt.$(basename ${out})
#     done
# done
# wc -l tmp/{lms,forms}.belagt.*
