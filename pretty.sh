#!/bin/bash

cd "$(dirname "$0")"
set -e -u
source functions.sh

for d in out out/nobsmjsme out/nobsmasme tmp; do
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
    < "$f" trans_annotate tmp/srctrg tmp/trgsrc 1 > out/nobsmjsme/"$b"
done

for f in out/nobsma/*; do
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    cat words-src-fad/nobsme/${pos}_nobsme.tsv > tmp/srctrg 2>/dev/null
    cat words-src-fad/smenob/${pos}_smenob.tsv > tmp/trgsrc 2>/dev/null
    < "$f" trans_annotate tmp/srctrg tmp/trgsrc 3 > out/nobsmasme/"$b"
done


# TODO: freq's should be normalised somehow; perhaps by simply
# cropping the corpus to the size of the smallest corpus
for f in out/nobsmasme/*; do
    <"$f" freq_annotate 1 freq/forms.nob \
        | freq_annotate 2 freq/forms.sma \
        | freq_annotate 3 freq/forms.sme >tmp/sma$(basename "$f")
done
for f in out/nobsmjsme/*; do
    <"$f" freq_annotate 1 freq/forms.nob \
        | freq_annotate 2 freq/forms.smj \
        | freq_annotate 3 freq/forms.sme >tmp/smj$(basename "$f")
done
