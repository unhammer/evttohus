#!/bin/bash

set -e -u


cat <<EOF
How many words from the src=fad dictionaries do we have candidates
for? (All numbers restricted to part-of-speech.)
EOF

cov () {
    lang=$1
    for pos in V N A nonVNA;do
        for f in out/nob${lang}sme/${pos}_*; do
            test -f "$f" && awk -v pos=${pos} -f coverage.awk "$f"
        done
    done | sort -t$'\t' -k2,2nr
}

for lang in sma smj; do
    echo
    cat <(echo -e "${lang}-candidates\t% sme\tsum sme\t% nob\tsum nob") \
        <(cov ${lang}) \
        | column -ts$'\t'
done
