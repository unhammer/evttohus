#!/usr/bin/gawk -f


# $ for lang in sma smj; do for pos in V N A; do
#     gawk  -F'\t' -v words=words/nobsmj/${pos}.tsv -f  para/pretty-kwic.awk freq/nob${lang}.para-kwic >para-nob${lang}.${pos}
#   done;done


BEGIN{
	OFS=FS="\t";
	while(getline<words)for(i=2;i<=NF;i++)t[$1][$i]++
}


function cmp_len(i1, v1, i2, v2)
{
	l1 = length(i1"")
	l2 = length(i2"")
	if (l1<l2) {
		return -1
	}
	else if (l1>l2) {
		return 1
	}
	else {
		return 0
	}
}
function cmp_minlen(i1, v1, i2, v2)
{
	l1 = minlen[i1""]
	l2 = minlen[i2""]
	if (l1<l2) {
		return -1
	}
	else if (l1>l2) {
		return 1
	}
	else {
		return 0
	}
}

length($3)<20 || length($4) <20 {next}

$1 in t && $2 in t[$1]{
	s[$1"\t"$2][$3"\t"$4]++
	f[$1"\t"$2]++
	if($1"\t"$2 in minlen) {
		if(minlen[$1"\t"$2]>length($3"\t"$4)) {
			minlen[$1"\t"$2]=length($3"\t"$4)
		}
	}
	else {
		minlen[$1"\t"$2]=length($3"\t"$4)
	}
}

END{
	PROCINFO["sorted_in"] = "cmp_minlen"
	for(srctrg in s) {
		i=1
		print f[srctrg],srctrg
		PROCINFO["sorted_in"] = "cmp_len"
		for(sents in s[srctrg]){
			print sents
			i++
			if(i>10)break
		}
		print ""
	}
}

