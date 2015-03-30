#!/bin/bash

set -e -u

dir=out

# Number of fad-words we have vs need candidates for:
already_in () {
    cut -f1 words/nob${candlang}/${pos}.tsv | sort -u
}
need_trans_for () {
    already_in | comm -23 fadwords/${pos}.nob -
}
got_cand_for () {
    cut -f1 ${dir}/nob${candlang}sme/${pos}${method}* 2>/dev/null| sort -u
}
got_ana_cand_for () {
    cut -f1 ${dir}/nob${candlang}sme/${pos}${method}_ana* 2>/dev/null| sort -u
}
got_missing_cand_for () {
    comm -12 <(need_trans_for) <(got_cand_for)
}
got_missing_ana_cand_for () {
    comm -12 <(need_trans_for) <(got_ana_cand_for)
}
got_freq_for () {
    cut -f1,5 ${dir}/nob${candlang}sme/${pos}${method}* 2>/dev/null | sort -u \
        | gawk -v need=<(need_trans_for) '
          BEGIN{while(getline<need)d[$0]++; s=0}
          $1 in d && $2>0 {s++; delete d[$1]}
          END{print s}'
}

for candlang in sma smj; do
    echo "== ${candlang} =="
    for pos in V N A; do
        echo "${pos}: $(need_trans_for |wc -l) nob words need translations"
        for method in _decomp _precomp _anymalign _cross _xfst _lexc '_*'; do
            missing=$(got_missing_cand_for |wc -l)
            missing_ana=$(got_missing_ana_cand_for |wc -l)
            freq=$(got_freq_for)
            if [[ ${missing} -gt 0 ]]; then
                if [[ ${method} = '_*' ]]; then method="(sum)";fi
                echo "${method}	"${missing}" had candidates,	"${missing_ana}" of these had analyses,	"${freq}" had corpus hits"
            fi
        done|column -ts$'\t'
        echo
    done
done
