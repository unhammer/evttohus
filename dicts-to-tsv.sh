#!/bin/bash

cd "$(dirname "$0")"
set -e -u

fad_dict2tsv () {
    # forall e[src=fad]:
    #   print lg/l/text
    #   forall mg/tg/t:
    #     print text()
    #   print "\n"
    xmlstarlet sel -t \
        -m '//e[@src="fad"]' -c './lg/l/text()' \
        -m './mg/tg/t' -o $'\t' -c './text()' \
        -b -n \
        "$@"
}

test -d words-src-fad || mkdir words-src-fad
cd words-src-fad

for dir in smenob nobsme; do
    test -d $dir || mkdir $dir
    for xml in $GTHOME/words/dicts/$dir/src/*.xml; do
        tsv=$dir/$(basename "$xml")
        tsv=${tsv%%.xml}.tsv
        if ! fad_dict2tsv "${xml}" > "${tsv}"; then
            # No fad hits for that file:
            test -s "${tsv}" || rm -f "${tsv}"
        fi
    done
done

cat <(cut -f1  nobsme/*.tsv) \
    <(cut -f2- smenob/*.tsv | tr '\t' '\n') \
    | sort -u > nob

cat <(cut -f1  smenob/*.tsv) \
    <(cut -f2- nobsme/*.tsv | tr '\t' '\n') \
    | sort -u > sme
