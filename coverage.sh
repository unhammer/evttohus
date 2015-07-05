#!/bin/bash

set -e -u

declare -r dir=out
declare -r srclang=nob
declare -r trglang=sme

# Number of fad-words we have vs need candidates for:
already_in () {
    cut -f1 words/${srclang}${candlang}/${pos}.tsv | sort -u
}
need_trans_for () {
    already_in | comm -23 fadwords/${pos}.${srclang} -
}
got_cand_for () {
    cut -f1 ${dir}/${srclang}${candlang}${trglang}/${pos}${method}* 2>/dev/null| sort -u
}
got_ana_cand_for () {
    cut -f1 ${dir}/${srclang}${candlang}${trglang}/${pos}${method}_ana* 2>/dev/null| sort -u
}
got_missing_cand_for () {
    comm -12 <(need_trans_for) <(got_cand_for)
}
got_missing_ana_cand_for () {
    comm -12 <(need_trans_for) <(got_ana_cand_for)
}
got_freq_for () {
    cut -f1,5 ${dir}/${srclang}${candlang}${trglang}/${pos}${method}* 2>/dev/null | sort -u \
        | gawk -v need=<(need_trans_for) '
          BEGIN{while(getline<need)d[$0]++; s=0}
          $1 in d && $2>0 {s++; delete d[$1]}
          END{print s}'
}

for candlang in sma smj; do
    echo "== ${candlang} =="
    for pos in V N A; do
        echo "${pos}: $(need_trans_for |wc -l) ${srclang} words need translations"
        for method in _decomp _decomplow _decompno _precomp _precomplow _precompno _anymalign _cross _xfst _lexc _syn _loan _gv '_*'; do
            missing=$(got_missing_cand_for |wc -l)
            missing_ana=$(got_missing_ana_cand_for |wc -l)
            freq=$(got_freq_for)
            if [[ ${missing} -gt 0 ]]; then
                if [[ ${method} = '_*' ]]; then method="(sum)";fi
                echo "${method}	"${missing}" had candidates,	"${missing_ana}" had cand's w/analyses,	"${freq}" had cand's in corpus"
            fi
        done|column -ts$'\t'
        echo
    done
done
