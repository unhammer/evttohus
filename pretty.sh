#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

for d in out out/nobsmjsme out/nobsmasme tmp tmp/nobsmjsme tmp/nobsmasme; do
    test -d $d || mkdir $d
done

trans_annotate () {
    # Ensure we have lines in the format
    #nob	candidate	sme
    # where candidate is in sma or smj
    gawk -v srctrg="$1" -v trgsrc="$2" -v col="$3" '
BEGIN{OFS=FS="\t";
  while(getline<srctrg){trans[$1][$2]++}
  while(getline<trgsrc){trans[$2][$1]++}
}
!($1 in trans) {
  trans[$1]["?????"]++
}
{
  for(trg in trans[$1]) {
    if(col==1) {
      print trg, $2, $1
    }
    else {
      print $1, $2, trg
    }
  }
}'
}

pos_glob () {
    case $1 in
        V*) echo "V*";;
        N*) echo "N*";;
        A*) echo "A*";;
        *)  echo "[^VNA]*";;
    esac
}

for f in out/smesmj/* spell/out/smesmj/*; do
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    cat words-src-fad/smenob/${pos}_smenob.tsv > tmp/srctrg 2>/dev/null
    cat words-src-fad/nobsme/${pos}_nobsme.tsv > tmp/trgsrc 2>/dev/null
    < "$f" trans_annotate tmp/srctrg tmp/trgsrc 1 > tmp/nobsmjsme/"$b"
done

for f in out/nobsma/* spell/out/nobsma/*; do
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    cat words-src-fad/nobsme/${pos}_nobsme.tsv > tmp/srctrg 2>/dev/null
    cat words-src-fad/smenob/${pos}_smenob.tsv > tmp/trgsrc 2>/dev/null
    < "$f" trans_annotate tmp/srctrg tmp/trgsrc 3 > tmp/nobsmasme/"$b"
done


# Normalise frequency sums (to the smallest corpora, ie. smj/sma):
sumnob=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/lms.nob)
sumsma=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/lms.sma)
sumsme=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/lms.sme)
sumsmj=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/lms.smj)
for f in tmp/nobsmasme/*; do
    b=$(basename "$f")
    <"$f" freq_annotate 1 freq/lms.nob ${sumnob} ${sumsma} \
        | freq_annotate 2 freq/lms.sma ${sumsma} ${sumsma} \
        | freq_annotate 3 freq/lms.sme ${sumsme} ${sumsma} \
        | sort -nr -k5,5 -k2,2 -t$'\t' \
        >out/nobsmasme/"$b"
done
for f in tmp/nobsmjsme/*; do
    b=$(basename "$f")
    <"$f" freq_annotate 1 freq/lms.nob ${sumnob} ${sumsmj} \
        | freq_annotate 2 freq/lms.smj ${sumsmj} ${sumsmj} \
        | freq_annotate 3 freq/lms.sme ${sumsme} ${sumsmj} \
        | sort -nr -k5,5 -k2,2 -t$'\t' \
        >out/nobsmjsme/"$b"
done
