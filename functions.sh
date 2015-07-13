#!/bin/bash

FAD_ONLY=${FAD_ONLY-true}
# by default, only generate suggestions from words that had src=fad in nobsme-dicts
# if env has false, generate suggestions from all words

if [[ -n $LOOKUP && $LOOKUP != "lookup -q -flags mbTT" ]]; then
        echo "Warning: overriding strange value of LOOKUP: $LOOKUP"
fi
export LOOKUP="lookup -q -flags mbTT"

psed () {
    perl -CSAD -wnpe "$@"
}

tabalign () {
    column -ts$'\t'
}

rev () {
    # /usr/bin/rev on OS X doesn't handle unicode. Just wonderful.
    perl -CSAD -wlnpe '$_=reverse($_)'
}

suffix_chargrams () {
    # hitparade of most popular suffixes up to fourgrams:
    psed 's/.*(.(.(.(.))))$/$1\n$2\n$3\n$4/' | sort | uniq -c | sort -n
}

lookup_good () {
    fst=$1
    $LOOKUP "${fst}" | grep -v '+?$' |grep .
}

preproc () {
    lang=$1
    shift
    $GTHOME/gt/script/preprocess --abbr=$GTHOME/langs/${lang}/tools/preprocess/abbr.txt "$@"
}

ana_no_prep () {
    lang=$1
    $LOOKUP $GTHOME/langs/${lang}/src/analyser-gt-desc.xfst
}

ana () {
    lang=$1
    shift
    preproc ${lang} "$@" | ana_no_prep ${lang}
}

lemma_per_line () {
    # Used by make-freq.sh
    # Note: if a form is ambiguous, it gets an unnaturally high lemma
    # "corpus count", but there's not really any simple way around
    # this, and we're not really after absolute corpus counts either
    # (this is more for comparing progress and whether something
    # exists at all)
    awk -F'\t' '/^$/{for(i in a)if(i)print i; for(i in a)delete a[i]} {sub(/\+.*/,"",$2);a[$2]++}'
}

to_freqlist () {
    sort|uniq -c|sort -nr|sed $'s/^ *//;s/ /\t/'
}

clean_punct () {
    sed "s/[…““’]/'/g" | tr $' ;/\\0123456789{}[]«»"_.?:-:,)(””!¶\t'"'" ' '
}

join_freq () {
    # Join two tsv lists by their second column
    freq1=$1
    freq2=$2
    (
        LC_ALL=C
        join -t$'\t' -j2 \
             <(sort -k2,2 -t$'\t' "${freq1}" ) \
             <(sort -k2,2 -t$'\t' "${freq2}")
    )
}

freq_annotate () {
    # Look up a column ($1) of candidates from stdin in freqfile ($2)
    # and append the freq to each line of the candidates.
    # sum is the sum of freqs, norm is the sum of a freqfile.
    awk -v column="$1" -v freqs="$2" -v sum="$3" -v norm="$4" '
BEGIN{
  OFS=FS="\t"
  while(getline<freqs)freq[$2]=$1
}
function ceil(xs) {
  x = sprintf("%d", xs)
  return (xs == int(x)) ? x : int(x)+1
}
{
  f=0
  n=split($column, words, "/")
  for(i=1;i<=n;i++) {
    f += freq[words[i]]
  }
  fn=f/(n+0.00000001)
  print $0,ceil(fn*norm/sum)
}'
}


clean_cmp_ana () {
    # Grep for compound analyses of a certain part of speech, and turn
    # output of lookup into tab-separated form followed by compound
    # lemmas
    lang=$1
    pos=$2
    if [[ ${lang} = nob ]]; then
        # nob for some reason has completely different analysis format :(
        grep "#+Cmp.*+${pos}[^#]*$" \
            | sed 's/+X+N/+N/g;s/+Nynorsk+N/+N/g' \
            | sed 's/+[^#+]*#+CmpS*+/	/g;
                   s/+[^#+]*#+CmpS*-/-	/g;
                   s/+[^#]*$//' \
            | sed 's/		*/	/g'
        # samarbeidsspørsmål	samarbeid	+N#+CmpS+spørs+X+N#+Cmp+mål+N+Neu+Pl+Indef
        # forsøksråd	for	+N#+Cmp+søk+N#+CmpS+råd+N+Neu+Sg+Indef
        # primærprodukt	primær+A#+Cmp+produkt+N+Neu+Sg+Indef
        # kjerneområde	kjerne	+N#+Cmp+område+N+Neu+Sg+Indef
        # kystfiskerlag	kystfisker	+N#+Cmp+lag+N+Neu+Pl+Indef
    else
        sed 's/\([^	+]*\)\([^#	]*\)+Cmp-/\1-\2+Cmp/g' \
            | grep "+Cmp-*#.*+${pos}[^#]*$" \
            | sed 's/+[^#]*#*/	/g' \
            | sed 's/		*/	/g' \
            | sed 's/	$//'
    fi
}

ana_to_lemmas () {
    psed '# nob analyser:
          s/\+(X|Nynorsk)\+N/+N/g;
          s/\+[^#+\n]*#\+CmpS*\+/\t/g;
          s/\+[^#+\n]*#\+CmpS*-/-\t/g;
          s/\+[^#\n]*$//;
          # all other analysers:
          s/\+[^#\n]*#*/\t/g;
          s/\t+/\t/g;
          s/\t$//'
}


convert_all () {
    lang=$1
    if [[ -n $GTBOUND ]]; then
        convert2xml $GTBOUND/orig/$lang & P1=$!
    else
        echo "GTBOUND not set, only converting GTFREE"
    fi
    convert2xml $GTFREE/orig/$lang & P2=$!
    wait $P1 $P2
}

ccat_all () {
    lang=$1
    if [[ -n $GTBOUND ]]; then
        cat <(ccat -a -l $lang $GTBOUND/converted/$lang) \
            <(ccat -a -l $lang $GTFREE/converted/$lang)
    else
        echo "GTBOUND not set, only ccat-ing GTFREE"
        ccat -a -l $lang $GTFREE/converted/$lang
    fi
    # Might as well include the few example sentences we have:
    if [[ $lang = sma ]]; then
        sort -u <(xmlstarlet sel -t -m '//x' -c 'text()' -n $GTHOME/words/dicts/smanob/src/*.xml) \
             <(xmlstarlet sel -t -m '//xt' -c 'text()' -n $GTHOME/words/dicts/nobsma/src/*.xml)
    fi
}


dict_xml2tsv () {
    dir=$1
    lang1=${dir%???}
    lang2=${dir#???}
    restriction=$2
    shift
    shift
    # forall e where $restriction
    #   print lg/l/text
    #   forall mg//tg/t:
    #     print text()
    #   print "\n"
    xmlstarlet sel -t \
        -m "//e${restriction}" -c './lg/l/text()' \
        -m "./mg//tg[@xml:lang='${lang2}' or not(@xml:lang)]/t" -o $'\t' -c './text()' \
        -b -n \
        "$@" | gawk -F'\t' '$1 && $2'
}

normalisePoS () {
    psed 's/(\w+)_/\u\L$1_/;
          s/Cc_/CC_/; s/Cs_/CS_/; s/(Pp|Prep)_/Pr_/; s/P_/Po_/; s/I_/Ij_/;
          s/_[a-z]{6,6}[.]/./;'
}

apertiumpos () {
    case "$1" in
        V) echo vblex;;
        N) echo n;;
        A) echo a;; # might become adj later!
        Adv) echo adv;;
        Pron) echo prn;;
        Po) echo po;;
        Pr) echo pr;;
        *) echo '[^<]*';;
    esac
}

dir2tsv () {
    # Will output into "$dir" under cwd
    restriction=$1
    dir=$2
    test -d ${dir} || mkdir ${dir}
    rm -f ${dir}/[VNA].tsv      # The main files we want
    # Some source directories are missing a lot of files, ensure at
    # least these exists:
    touch "${dir}"/{V,N,A,nonVNA}.tsv
    if [[ ${dir} = smesmj ]]; then
        for csv in $GTHOME/words/dicts/${dir}/src/*.csv; do
            tsv=${dir}/$(basename "$csv")
            tsv=${tsv%%.csv}.tsv
            tsv=$(echo "$tsv" | normalisePoS)
            cut -f1-2 <"${csv}" > "${tsv}"
        done
    elif [[ ${dir} = smesma ]]; then
        # Do not try with sme-nob, takes an hour
        adir=sme-sma
        lt-expand ../apertium-${adir}.${adir}.dix > apertium-${adir}.${adir}.exp
        for pos in V N A Adv Pron Po Pr; do
            apos=$(apertiumpos ${pos})
            grep -i "<${apos}>.*:.*<${apos}>" apertium-${adir}.${adir}.exp \
                | grep -v '<prop>' | sed 's/<[^>]*>//g' \
                | sed 's/:[<>]:/:/' \
                | tr ':' '\t' >"${dir}/${pos}_apertium.tsv"
        done
    elif [[ ${dir} != smjnob ]]; then
        for xml in $GTHOME/words/dicts/${dir}/src/*_${dir}.xml; do
            tsv=${dir}/$(basename "${xml}")
            tsv=${tsv%%.xml}.tsv
            tsv=$(echo "$tsv" | normalisePoS)
            # Why does this sometimes return non-zero even though good output?
            dict_xml2tsv ${dir} "${restriction}" "${xml}" > "${tsv}" || true
        done
    fi
    if [[ ${dir} = nobsmj || ${dir} = smjnob ]]; then
        kintel2tsv ${dir}
        # Kintel files will contain _kintel in the name, so we can
        # separate them out in canonicalise.sh; but we only look at
        # plain N.tsv etc. when generating candidates; so N_kintel.tsv
        # is appended to plain N.tsv below.
    fi
    if [[ ${dir} = nob* ]]; then
        for pos in V N A; do
            <"$GTHOME/words/dicts/${dir}/src/${pos}_${dir}.xml" \
                awk -F' ::: ' '$2{print $1"\t"$2}' >"${dir}/bad_${pos}.tsv"
        done
        touch "${dir}/bad_nonVNA.tsv" # TODO: some dirs don't even have nonVNA xml's
    elif [[ ${dir} = sme* ]]; then
        lang1=${dir%???}
        lang2=${dir#???}
        for pos in V N A; do
            apos=$(apertiumpos "${pos}")
            <"../apertium-${lang1}-${lang2}.${lang1}-${lang2}.dix" \
                gawk -v pos="${apos}" -F' ::: ' '$2 && $3==pos{print $1"\t"$2}' \
                >"${dir}/bad_${pos}.tsv"
        done
        touch "${dir}/bad_nonVNA.tsv" # TODO: some dirs don't even have nonVNA xml's
    fi
    # We only use files named $dir/$pos_$dir.tsv, e.g.
    # smenob/V_smenob.tsv; append some entries from the more funnily
    # named files to the ordinary-named files. 
    for f in ${dir}/[VNA]_{Pl,G3,mwe,NomAg,kintel}*.tsv ; do
        [[ -f $f ]] || continue
        b=$(basename "$f")
        pos=${b%%_*}
        dir=$(dirname "$f")
        cat "$f" >> "${dir}/${pos}.tsv"
    done
}

dir2tsv_fad () {
    dir2tsv '[contains(@src,"fad") or .//*[contains(@src,"fad")]]' "$@"
}

mono_from_bi () {
    lang=$1
    pos=$2
    if [[ ${pos} = nonVNA ]]; then
        pos=[^VNA]
    fi
    cat <(cut -f1  ${lang}???/${pos}*.tsv) \
        <(cut -f2- ???${lang}/${pos}*.tsv | tr '\t' '\n') \
        | sort -u
}


kintel2tsv () {
    dir=$1
    lang1=${dir%???}
    lang2=${dir#???}
    dir2=${lang1}2${lang2}
    test -d ${dir} || mkdir ${dir}
    for pos in V N A nonVNA; do
        if [[ $pos = nonVNA ]]; then
            restriction="[.//l[not(@pos='V' or @pos='N' or @pos='A' or @obt='V' or @obt='N' or @obt='A')]]"
        else
            restriction="[.//l[(@pos='${pos}' or @obt='${pos}')]]"
        fi
        xml=$GTHOME/words/dicts/smjnob-kintel/src/${dir2}/*.xml
        tsv=${dir}/${pos}_kintel.tsv
        # Extract the finished translations:
        dict_xml2tsv ${dir} "${restriction}" ${xml} > "${tsv}" || true
        # but also include the unfinished ones (no .//t):
        xmlstarlet sel -t \
            -m "//e${restriction}" -c './lg/l/text()' \
            -m './mg[count(.//t)=0]/trans_in' -o $'\t' -c './/span[not(contains(@STYLE,"font-style:italic"))]/text()' \
            -b -n \
            ${xml} \
            | psed 's/ el[.] /\t/g' \
            | psed 's/\([^)]*\)/\t/g' \
            | psed "s/( [bDdfGgjlmnŋprsVvbd][bDdfGgjlmnŋprsVvbdthkRVSJN']*| -\p{L}+-)*(\$|[ ,.;])/\t/g" \
            | psed 's/\t[0-9]+/\t/g' \
            | psed 's/\t\t/\t/g;s/^\t//' > "${tsv}".unchecked
    done
}


lexc2lms () {
    # ugly hack to grep some lemmas out of lexc's
    sed 's/!.*//' \
        | grep -v '^[;   ]*[@+-:<]' \
        | grep ':.* .*;' \
        | sed 's/[:+].*//' \
        | tr -d '#%' \
        | sed 's/^ *//'
}

posgrep () {
    pos=$1
    if [[ $pos = nonVNA ]]; then
        grep -v "+[VNA]+[^#]*$"
    else
        grep "+${pos}+[^#]*$"
    fi
}

ana_to_forms_pos () {
    # given ana input, output tab-separated
    #FORM	MAINPOS
    gawk -F'\t|[+]' '
      $1 {
        sub(/[^\t]*#/,"")
        pos="nonVNA"
        for(i=NF;i>=0;i--) if($i~/^[VNA]$/){
          pos=$i
          break
        }
        print $1"\t"pos
      }
'
}
ana_to_forms_lms_of_pos () {
    # Used in anymalign
    pos=$1
    posgrep "${pos}" \
        | ana_to_lemmas \
        | awk 'BEGIN{OFS=FS="\t"} {lm=$2;for(i=3;i<=NF;i++)lm=lm $i;print $1,lm}' \
        | sort -u
    # We just concatenate compound lemmas here
}

all_lms_of_pos () {
    lang=$1
    pos=$2
    lexc2lms < $GTHOME/langs/${lang}/src/morphology/lexicon.lexc \
        | cat - words/all.${lang} <(cut -f2 freq/forms.${lang}) \
        | sort -u \
        | ana ${lang} \
        | posgrep "${pos}" \
        | cut -f1 \
        | LC_ALL=C sort -u
}

rev_tsv () {
    gawk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $i,$1}' "$@"
}

cat_tsv () {
    gawk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $1,$i}' "$@"
}

cat_dict () {
    l1=$1
    l2=$2
    pos=$3
    [[ -f words/${l1}${l2}/${pos}_apertium.tsv ]] && cat_tsv words/${l1}${l2}/${pos}_apertium.tsv
    [[ -f words/${l2}${l1}/${pos}_apertium.tsv ]] && rev_tsv words/${l2}${l1}/${pos}_apertium.tsv 
    rev_tsv words/${l2}${l1}/${pos}.tsv &&
    cat_tsv words/${l1}${l2}/${pos}.tsv
}



synonyms () {
    lang=$1
    pos=$2
    # Follows synonyms in dictionaries, but only for "one level".
    # First we create a big "src→trg" dictionary where the first
    # column is the src word, and the others are trg translations of
    # that word. One trg may appear in several lines, e.g.
    # x b c
    # y b d
    # (where x and y might come from different languages, or just from
    # different directions of the same pair). We skip the first (src)
    # column, and create the cross product of all words that appear in
    # the same lines, finally giving
    # b c
    # b d
    # c b
    # c d
    # d b
    # d c
    :|gawk \
        -v trgsrc=<(cat words/${lang}???/${pos}.tsv) \
        -v srctrg=<(cat words/???${lang}/${pos}.tsv) '
        BEGIN{
           OFS=FS="\t"
           while(getline<srctrg) for(i=2;i<=NF;i++)d[$1][$i]++
           while(getline<trgsrc) for(i=2;i<=NF;i++)d[$i][$1]++
           for(f in d){o=f;for(t in d[f])o=o"\t"t;print o}
        }' \
             | gawk '
        BEGIN{
           OFS=FS="\t"
        }
        {
          for(i=2;i<=NF;i++) for(j=2;j<=NF;j++) d[$i][$j]++
        }
        END{
          for(a in d) for(b in d[a]) if(a!=b) print a,b
        }'
}

loans () {
    local -r srclang=$1
    local -r trglang=$2
    local -r dopos=$3
    
    local words=
    if ${FAD_ONLY}; then
        words=fadwords
    else
        words=words
    fi

    for k in "${!src[@]}"; do
        if [[ ${pos[k]} != ${dopos} ]]; then continue; fi
        grep "..${src[k]}$" "${words}"/${pos[k]}."${srclang}" \
        | sed "s/${src[k]}$/${trg[k]}/" \
        | ana "${trglang}" \
        | grep -v +Cmp | posgrep ${pos[k]} \
        | cut -f1 \
        | grep "${trg[k]}$" \
        | awk -v src=${src[k]} -F"${trg[k]}$" '{print $1 src "\t" $0}'
    done | sort -u
}

gaerjiste-vaalteme () {
    if ${FAD_ONLY}; then
        words=fadwords
    else
        words=words
    fi
    gawk -v w="${words}" -v pos="$1" 'BEGIN{OFS=FS="\t"; while(getline<(w"/"pos".nob"))nob[$0]} $1 in nob{print}' "$2"
}
