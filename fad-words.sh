#!/bin/bash

# Find words with src=fad from smenob/nobsme, and pair them with their
# frequency in the fad-corpus. Give it some argument to skip convert2xml.

noconvert=$1

source ~/virt_env/ct-svn/bin/activate

set -e -u

SUM_NOB=$(mktemp -t fad-words.XXXXXXXXXXXX)
cleanup () {
    rm -f "${SUM_NOB}"
    kill $$
}
trap cleanup EXIT



smenob_fad () {
    xmlstarlet sel -t -m '//e[@src="fad"]/mg/tg/t/text()' -c . -n $GTHOME/words/dicts/smenob/src/*.xml
}
nobsme_fad () {
    xmlstarlet sel -t -m '//e[@src="fad"]/lg/l/text()' -c . -n $GTHOME/words/dicts/nobsme/src/*.xml
}

dicts_fad () {
    unset LC_ALL
    # words with src=fad in words/dicts/{smenob,nobsme}
    cat <(smenob_fad) <(nobsme_fad) | LC_ALL=C sort -u
}

corp_fad () {
    lang=$1
    if [[ -z $noconvert ]]; then
        echo "Converting corpus to XML first …" >&2
        convert2xml  $GTFREE/orig/$lang/{admin,facta,laws,news,science}
        convert2xml $GTBOUND/orig/$lang/{admin,facta,laws,news,science}
    else
        echo "Assuming corpus already converted …" >&2
    fi
    cat <(ccat -a -l $lang  $GTFREE/converted/$lang/{admin,facta,laws,news,science}) \
        <(ccat -a -l $lang $GTBOUND/converted/$lang/{admin,facta,laws,news,science})
}

preprocess () {
    lang=$1
    $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/$lang/tools/preprocess/abbr.txt
}

hitparade_fad () {
    unset LC_ALL
    lang=$1
    corp_fad $lang | preprocess $lang |\
      sort | uniq -c | sed $'s/^ *//;s/ /\t/' |\
      tee >(awk -F'\t' '{sum+=$1} END{print sum}' > "${SUM_NOB}")|\
      LC_ALL=C sort -k2 -t$'\t'
}


LC_ALL=C join -t$'\t' -a1 -11 -22 <(dicts_fad) <(hitparade_fad nob) |\
 awk -F'\t' 'BEGIN{OFS=FS} $2==""{$2=0} {print $2,$1}'
echo -n $'sum\t'; cat "${SUM_NOB}"
# This sum is larger than the sum of word-frequencies printed, since
# we only print those with src=fad-matches


# bzcat corpora/*.nb.txt.bz2 ~/corpora/Copyright/bokmål.txt.bz2 | $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/nob/tools/preprocess/abbr.txt |sort |uniq -c|sed $'s/^ *//;s/ /\t/'|tee >(awk -F'\t' '{sum+=$1} END{print sum}' > SUM_NOB) |LC_ALL=C sort -k2 -t$'\t'  >hitparade_nonfad.tsv   
