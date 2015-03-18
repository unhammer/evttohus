#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

## Run like:

# < A_lexc_noana_01_sme gawk -v mostly=bad -v pos=A -f tsv2xml.awk | xmllint --format -


BEGIN {
  srclang="nob"
  trglang="smj"
  OFS=FS="\t"
  print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  print "<r id=\""srclang trglang"\" xml:lang=\""srclang"\">"
}
function del_ar(ar) {
  for(i in ar) {
    delete ar[i]
  }
}

function output() {
	if(!q) for(src in good) {
      print "<e><lg><l pos=\""pos"\" src=\"fad\">"src"</l></lg><mg><tg>"
      for(trg in good[src]) {
        print "<t pos=\""pos"\">"trg"</t>"
      }
      print "</tg></mg></e>"
    }
}


/^ *$/ {
	output()
  q=0
	del_ar(good)
	next
}

/^[?-]/{q++}

/^[+]/ || (mostly=="good" && $2){
  sub(/^[+]/,"")
  good[$1][$2]++
}

/^[@]/||(mostly=="bad" && $2){
  sub(/^[@]/,"")
  bad[$1][$2]++
}

END{
	output()
  print "<!-- Bad suggestions, remove next time round: -->"
  for(src in bad) for(trg in bad[src]) print "<!-- "src" ::: "trg" -->"
  print "</r>"
}
