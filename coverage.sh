#!/bin/bash

set -e -u


cat <<EOF
How many words from the src=fad dictionaries do we have candidates
for? (All numbers restricted to part-of-speech, so SUM SME/NOB is how
many src=fad words there are from words/dicts/{smenob,nobsme} for that
PoS; % in FST is how many of SUM candidates had a same-PoS FST
analysis; all counts are without duplicates.)
EOF

cov () {
    lang=$1
    for pos in V N A nonVNA; do
        for f in out/nob${lang}sme/${pos}_*; do
            test -f "$f" && awk -v pos=${pos} -f coverage.awk "$f"
        done
        cat out/nob${lang}sme/${pos}_* >tmp/${pos}_all 2>/dev/null
        awk -v pos=${pos} -f coverage.awk tmp/${pos}_all
    done \
        | sed 's%^[^/]*/%%' \
        | sort -t$'\t' -k2,2nr -k4,4nr -k3,3nr -k5,5nr
}

for lang in sma smj; do
    echo
    cat <(echo -e "${lang}-candidates\t% sme\tsum sme\t% nob\tsum nob\t% in FST\tsum ${lang}"|tr [:lower:] [:upper:]) \
        <(cov ${lang}) \
        | column -ts$'\t'
done
