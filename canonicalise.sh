#!/bin/bash

set -e -u
cd "$(dirname "$0")"
source functions.sh

dir=$1
fromlang=${dir%???}
candlang=${dir#???}
if [[ ${fromlang} = nob ]]; then
    fromfield=1
elif [[ ${fromlang} = sme ]]; then
    fromfield=3
else
    echo "Unknown fromlang ${fromlang}" >&2
    exit 1
fi
finaldir=nob${candlang}sme
para_hits=tmp/${dir}_para-hits


pos_glob () {
    case $1 in
        V*) echo "V*";;
        N*) echo "N*";;
        A*) echo "A*";;
        *)  echo "[^VNA]*";;
    esac
}
pos_name () {
    case $1 in
        V*) echo V ;;
        N*) echo N ;;
        A*) echo A ;;
        *)  echo nonVNA ;;
    esac
}


# Each block below here works on all files of a certain "incoming"
# folder and outputs the processed files to an "outgoing" folder; the
# next block uses that outgoing folder as its own incoming folder; the
# last one outputs to out/${finaldir}. They all empty out and
# re-create the outgoing folder before processing.

add_thirdlang () {
    inc=$1
    out=$2
    echo "$dir: Add translations from ${fromlang} so we get ${finaldir} ..."
    for f in ${inc}/*; do
        test -f "$f" || continue
        b=$(basename "$f")
        pos=$(pos_glob "$b")
        <"$f" gawk \
            -v fromlang=${fromlang} \
            -v smenob=<(cat fadwords/smenob/${pos}.tsv 2>/dev/null) \
            -v nobsme=<(cat fadwords/nobsme/${pos}.tsv 2>/dev/null) \
            -f trans_annotate.awk \
            >${out}/"$b"
    done
}

skip_existing () {
    inc=$1
    out=$2
    echo "$dir: Skip ${candlang} translations where nob/${candlang} was already in \$GTHOME/words/dicts (or marked bad) ..."
    for f in ${inc}/*; do           # skipping spell/out/${dir}/* for now
        test -f "$f" || continue
        b=$(basename "$f")
        pos_glob=$(pos_glob "$b")
        pos_name=$(pos_name "$b")
        <"$f" gawk \
            -v dict=<(cat words/nob${candlang}/${pos_glob}.tsv) \
            -v badf=<(cat words/nob${candlang}/bad_${pos_name}.tsv) '
        BEGIN{
          OFS=FS="\t"
          while(getline<dict){ src[$1]++; for(i=2;i<=NF;i++) trg[$i]++ }
          while(getline<badf){ bad[$1][$2]++ }
        }
        $1 in src || $2 in trg || ($1 in bad && $2 in bad[$1]) {next}
        {print}' \
            >${out}/"$b"
    done
    echo "$dir: Get para hits of all candidates ..."
    para/count-para-hits.sh <(sort -u ${out}/*) freq/${dir}.lemmas.ids > ${para_hits}
}

spell_norm () {
    inc=$1
    out=$2
    if [[ ${candlang} = smj ]]; then
        echo "$dir: Add suggestions with reformed spelling for ${candlang} ..."
        # See also nob2smj-loan.sh which creates loans directly using
        # these rules (but with a strict lexicalised-smj-filter, no compounds).
        for f in ${inc}/*; do
            b=$(basename "$f")
            <"$f" gawk '
            BEGIN{ OFS=FS="\t" }

            # The matches for end-of-line _only_ print the changed version:
            $1 ~ /i$/  && $2 ~ /ija$/ {       gsub(/ija$/, "iddja", $2);        print; next }
            $1 ~ /og$/ && $2 ~ /oga$/ {       gsub(/oga$/, "åvggå", $2);        print; next }
            $1 ~ /[ée]$/ && $2 ~ /ea$/ {      gsub(/ea$/, "iedja", $2);         print; next }
            $1 ~ /et$/ && $2 ~ /[^i]ehtta$/ { gsub(/[^i]ehtta$/, "iehtta", $2); print; next }
            $1 ~ /ek$/ && $2 ~ /[^i]ehkka$/ { gsub(/[^i]ehkka$/, "iehkka", $2); print; next }
            $1 ~ /ol$/ && $2 ~ /ola$/ {       gsub(/ola$/, "åvllå", $2);        print; next }
            $1 ~ /em$/ && $2 ~ /[^i]ebma$/ {  gsub(/[^i]ebma$/, "iebma", $2);   print; next }
            $1 ~ /om$/ && $2 ~ /oma$/ {       gsub(/oma$/, "åvmmå", $2);        print; next }
            $1 ~ /ør$/ && $2 ~ /ørra$/ {      gsub(/ørra$/, "erra", $2);        print; next }
            $1 ~ /ere$/ && $2 ~ /[^i]erit$/ { gsub(/erit$/, "ierit", $2);       print; next }

            # If we reached this far, try also changing in the middle of words,
            # but be safe and print the unchanged candidate as well:
            $1 ~ /i/  && $2 ~ /ija/ {         print; gsub(/ija/, "iddja", $2); print }
            $1 ~ /og/ && $2 ~ /oga/ {         print; gsub(/oga/, "åvggå", $2); print }
            $1 ~ /et/ && $2 ~ /[^i]ehtta/ {   print; gsub(/[^i]ehtta/, "iehtta", $2); print }
            $1 ~ /ek/ && $2 ~ /[^i]ehkka/ {   print; gsub(/[^i]ehkka/, "iehkka", $2); print }
            $1 ~ /ol/ && $2 ~ /ola/ {         print; gsub(/ola/, "åvllå", $2); print }
            $1 ~ /em/ && $2 ~ /[^i]ebma/ {    print; gsub(/[^i]ebma/, "iebma", $2); print }
            $1 ~ /om/ && $2 ~ /oma/ {         print; gsub(/oma/, "åvmmå", $2); print }
            $1 ~ /ør/ && $2 ~ /ørra/ {        print; gsub(/ørra/, "erra", $2); print }
            { print }
            ' | sort -u >${out}/"$b"
        done
    else
        for f in ${inc}/*; do
            b=$(basename "$f")
            sort -u "$f" > ${out}/"$b"
        done
    fi
}

add_freq () {
    inc=$1
    out=$2
    echo "$dir: Annotate with frequency and parallel sentence hits ..."
    # Normalise frequency sums (to the smallest corpora, ie. smj/sma):
    sumnob=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.nob)
    sumcand=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/combined.${candlang})
    sumsme=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.sme)
    for f in ${inc}/*; do
        b=$(basename "$f")
        pos=$(pos_name "$b")
        echo -n "$b "
        <"$f" freq_annotate 1 freq/combined.nob         ${sumnob}  ${sumcand} \
            | freq_annotate 2 freq/combined.${candlang} ${sumcand} ${sumcand} \
            | freq_annotate 3 freq/combined.sme         ${sumsme}  ${sumcand} \
            | sort -u \
            | gawk -v from=${fromfield} -v hitsf=${para_hits} '
            # Let field 7 be count of hits in parallel sentences:
            BEGIN{ OFS=FS="\t"; while(getline<hitsf) hits[$2][$3]=$1 }
            {
              hits[$from][$2] += 0       # default 0 if empty
              print $0, hits[$from][$2]
            } 
        ' \
            | awk '
            # Let field 8 be the candidate frequency normalised by
            # the difference of this frequency and input frequency
            # (only for sorting, we remove this field afterwards):
            BEGIN{OFS=FS="\t"}
            {diff=$5-$4-$6; if(diff<0) diff=-diff; if(diff==0) diff=1; print $0, $5/diff}
        ' \
            | sort -k7,7nr -k8,8nr -k5,5nr -k2,2 -t$'\t' \
            | cut -f1-7 \
            >${out}/"$b"
    done
    echo
}

split_kintel () {
    inc=$1
    out=$2
    if [[ ${candlang} = smj ]]; then
        echo "$dir: Split into Kintel vs non-Kintel ..."
        # This is a bit messy: We create one "regular" file in ${out},
        # which is further split into ana/noana below, while the
        # _kintel file goes straight into out/${finaldir}, later
        # merged with the actual kintel suggestions by
        # merge-kintel.sh.
        rm -f out/${dir}_*_kintel # since the below gawk *appends*
        for f in ${inc}/*; do
            b=$(basename "$f")
            pos=$(pos_name "$b")
            kintelfile=out/${dir}_${pos}_kintel
            <"$f" gawk -v dict=<(cat words/nobsmj/${pos}*_kintel.tsv) -v kintelf=${kintelfile} '
            BEGIN{
              OFS=FS="\t"
              while(getline<dict) if($2) kintel[$1]++
            }
            $1 in kintel {
              print > kintelf
              next
            }
            {
              print
            }' >${out}/"$b"
        done
    else
        for f in ${inc}/*; do
            b=$(basename "$f")
            cat "$f" > ${out}/"$b"
        done
    fi
}

split_fst () {
    inc=$1
    out=$2

    posfile=tmp/${dir}_${candlang}.pos
    echo "$dir: Get main PoS of all candidates ..."
    cut -f2 ${inc}/* \
        | ana ${candlang} \
        | ana_to_forms_pos \
        | sort -u > ${posfile}

    echo "$dir: Split based on whether same-pos analysis in FST ..."
    for f in ${inc}/*; do
        b=$(basename "$f")
        pos=$(pos_name "$b")
        goodfile=${out}/"$b"_ana
        badfile=${out}/"$b"_noana
        if [[ $b = *_nob ]]; then groupfield=1; else groupfield=3; fi
        <"$f" gawk \
            -v g=${groupfield} \
            -v pos=${pos} -v posf=${posfile} \
            -v badf="${badfile}" -v goodf="${goodfile}" '
      # Split into ana/noana files depending on whether FST gave a same-pos analysis:
      BEGIN{
        OFS=FS="\t"
        while(getline<posf) ana[$2][$1]++
        line[goodf]=line[badf]=0
        suf[goodf]=suf[badf]=0
      }
      {
        if($2 in ana[pos]){
          curf = goodf
        }
        else {
          curf = badf
        }
        if(curf in prev && prev[curf] != $g) {
          # Source word changed, maybe increase the file suffix:
          line[curf]++
          if(line[curf]>1000) {
            line[curf]=0
            suf[curf]++
          }
        }
        print > sprintf("%s_%02d", curf, suf[curf])
        prev[curf]=$g
      }
      '
    done
}

split_singles () {
    inc=$1
    out=$2
    echo "$dir: Split into single-candidates vs multiple ..."
    for f in ${inc}/*; do
        b=$(basename "$f")
        if [[ ${fromlang} = nob ]]; then groupfield=1; else groupfield=3; fi
        <"$f" gawk -F'\t' -v g=${groupfield} \
                          -v singles=${out}/"$b"_singles \
                          -v multis=${out}/"$b"_multis '
      function out() { 
        if(n==1) { print lines > singles }
        else { print lines > multis }
        lines=""
        n=0 
      }
      prev != $g { out() }
      END { if(lines) out() }
      $2 {
        if(lines) { lines=lines"\n"$0 }
        else { lines=$0 }
        n++
        prev = $g
      }'
    done
}

rev_blocks () {
    inc=$1
    out=$2
    echo "$dir: Reverse-sort and insert empty lines ..."
    for f in ${inc}/*; do
        b=$(basename "$f")
        if [[ ${fromlang} = nob ]]; then groupfield=1; else groupfield=3; fi
        revfield=$(( 8 - ${groupfield} ))
        <"$f" rev | sort -k${revfield},${revfield} -k6,6 -t$'\t' | rev \
            | gawk -F'\t' -v g=${groupfield} '
      # Just print an empty line whenever the source word changes:
      prev != $g { print "" }
      {
        print
        prev = $g
      }' >${out}/"$b"
    done
}


# This is where it happens:

inc=out/${dir}
for fn in add_thirdlang skip_existing spell_norm add_freq split_kintel split_fst split_singles rev_blocks; do
    out=tmp/${dir}_${fn}
    rm -rf ${out}; mkdir ${out}
    ${fn} ${inc} ${out}
    inc=${out}
done

out=out/${finaldir}
for f in ${inc}/*; do
    b=$(basename "$f")
    cat "$f" > ${out}/"$b"_${fromlang}
done
echo "$dir: done."
