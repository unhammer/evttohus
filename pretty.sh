#!/bin/bash

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
fromlang=${dir%???}
candlang=${dir#???}

pos_glob () {
    case $1 in
        V*) echo "V*";;
        N*) echo "N*";;
        A*) echo "A*";;
        *)  echo "[^VNA]*";;
    esac
}

for f in out/${dir}/* spell/out/${dir}/*; do
    test -f "$f" || continue
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    cat words-src-fad/smenob/${pos}_smenob.tsv > tmp/smenob 2>/dev/null
    cat words-src-fad/nobsme/${pos}_nobsme.tsv > tmp/nobsme 2>/dev/null
    <"$f" gawk \
        -v fromlang=${fromlang} \
        -v smenob=tmp/smenob -v nobsme=tmp/nobsme \
        -f trans_annotate.awk \
        >tmp/nob${candlang}sme/"$b"
done


# Normalise frequency sums (to the smallest corpora, ie. smj/sma):
sumnob=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.nob)
sumcand=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/combined.${candlang})
sumsme=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.sme)
for f in tmp/nob${candlang}sme/*; do
    b=$(basename "$f")
    <"$f" freq_annotate 1 freq/combined.nob ${sumnob}  ${sumcand} \
        | freq_annotate 2 freq/combined.sma ${sumcand} ${sumcand} \
        | freq_annotate 3 freq/combined.sme ${sumsme}  ${sumcand} \
        | awk 'BEGIN{OFS=FS="\t"} {diff=$5-$4-$6;if(diff<0)diff=-diff;if(diff==0)diff=1; print $0,$5/diff}' \
        | sort -k7,7nr -k5,5nr -k2,2 -t$'\t' \
        | awk 'BEGIN{OFS=FS="\t"} {print $1,$2,$3,$4,$5,$6}' \
        >out/nob${candlang}sme/"$b"
done
