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
        join -t$'\t' -v1 \
            <(sort -u "$f") \
            <(cat words/${dir}/${pos}*.tsv | sort -u) \
            >tmp/${dir}/"$b"
    fi
done
    
echo "Add translations from ${fromlang} so we get nob${candlang}sme ..."
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
        >tmp/nob${candlang}sme/"$b"_${fromlang}
done

echo "Get main PoS of all candidates ..."
cut -f2 tmp/nob${candlang}sme/* \
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
for f in tmp/nob${candlang}sme/*; do
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
            {diff=$5-$4-$6;if(diff<0)diff=-diff;if(diff==0)diff=1; print $0,$5/diff}' \
        | sort -k7,7nr -k5,5nr -k2,2 -t$'\t' \
        | gawk -v pos=${pos} -v posf=tmp/${candlang}.pos '
            # Let field 7 be true iff the FST gave a same-pos analysis:
            BEGIN{ OFS=FS="\t"; while(getline<posf)ana[$2][$1]++ }
            { print $1,$2,$3,$4,$5,$6,$2 in ana[pos] }' \
        | gawk -v from=${fromfield} -v hitsf=<(para/count-para-hits.sh "$f" freq/${dir}.lemmas.ids) '
            # Let field 8 be count of hits in parallel sentences:
            BEGIN{ OFS=FS="\t"; while(getline<hitsf) hits[$1][$2]++ }
            !($from in hits) || !($2 in hits[$from]) { hits[$from][$2]=0 }
            { print $1,$2,$3,$4,$5,$6,$7,hits[$1][$2] } ' \
        >out/nob${candlang}sme/"$b"
done
echo
