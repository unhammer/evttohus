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
outdir=nob${candlang}sme

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

echo "Skip translations that were already in \$GTHOME/words/dicts (excepting Kintel) ..."
for f in out/${dir}/* spell/out/${dir}/*; do
    test -f "$f" || continue
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    if [[ ${dir} = nobsmj ]]; then
        sort -u "$f" > tmp/${dir}/"$b"
    else
        <"$f" gawk -v dict=<(cat words/${dir}/${pos}*.tsv) '
          BEGIN{OFS=FS="\t";while(getline<dict){src[$1]++; for(i=2;i<=NF;i++)trg[$i]++}}
          $1 in src || $2 in trg {next} {print}' \
          >tmp/${dir}/"$b"
    fi
done

echo "Get para hits of all candidates ..."
para/count-para-hits.sh <(sort -u tmp/${dir}/*) freq/${dir}.lemmas.ids > tmp/${dir}.para-hits

echo "Add translations from ${fromlang} so we get ${outdir} ..."
for f in tmp/${dir}/*; do
    test -f "$f" || continue
    b=$(basename "$f")
    pos=$(pos_glob "$b")
    cat fadwords/smenob/${pos}.tsv > tmp/smenob 2>/dev/null
    cat fadwords/nobsme/${pos}.tsv > tmp/nobsme 2>/dev/null
    <"$f" gawk \
        -v fromlang=${fromlang} \
        -v smenob=tmp/smenob -v nobsme=tmp/nobsme \
        -f trans_annotate.awk \
        >tmp/${outdir}/"$b"_${fromlang}
done

echo "Get main PoS of all candidates ..."
cut -f2 tmp/${outdir}/* \
    | ana ${candlang} \
    | gawk -F'\t|[+]' '
       $1{ sub(/.*#/,""); pos="nonVNA"; for(i=NF;i>=0;i--)if($i~/^[VNA]$/){pos=$i;break}; ana[$1][pos]++ }
       END{ for(form in ana)for(pos in ana[form])print form"\t"pos }
'   | sort -u > tmp/${candlang}.pos

# Normalise frequency sums (to the smallest corpora, ie. smj/sma):
sumnob=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.nob)
sumcand=$(awk -F'\t' '{sum+=$1}END{print sum}' freq/combined.${candlang})
sumsme=$(awk  -F'\t' '{sum+=$1}END{print sum}' freq/combined.sme)
echo "Annotate with frequency and whether FST had same-pos analysis ..."
for f in tmp/${outdir}/*; do
    b=$(basename "$f")
    pos=$(pos_name "$b")
    echo -n "$b "
    <"$f" freq_annotate 1 freq/combined.nob ${sumnob}  ${sumcand} \
        | freq_annotate 2 freq/combined.sma ${sumcand} ${sumcand} \
        | freq_annotate 3 freq/combined.sme ${sumsme}  ${sumcand} \
        | sort -u \
        | awk '
            # Let field 7 be the candidate frequency normalised by difference of this frequency and input frequency:
            BEGIN{OFS=FS="\t"}
            {diff=$5-$4-$6;if(diff<0)diff=-diff;if(diff==0)diff=1; print $0, $5/diff}' \
        | gawk -v from=${fromfield} -v hitsf=tmp/${dir}.para-hits '
            # Let field 8 be count of hits in parallel sentences:
            BEGIN{ OFS=FS="\t"; while(getline<hitsf) hits[$2][$3]=$1 }
            !($from in hits) || !($2 in hits[$from]) { hits[$from][$2]=0 }
            { print $0, hits[$1][$2] } ' \
        | sort -k7,7nr -k8,8nr -k5,5nr -k2,2 -t$'\t' \
        | gawk -v pos=${pos} -v posf=tmp/${candlang}.pos '
            # Overwrite field 7 with true iff the FST gave a same-pos analysis:
            BEGIN{ OFS=FS="\t"; while(getline<posf)ana[$2][$1]++ }
            { $7=$2 in ana[pos]; print }' \
        >out/${outdir}/"$b"
done
echo
