#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

## Run like:

# cat A_* | gawk -v pos=A -f tsv2dix.awk


BEGIN {
  srclang="nob"
  trglang="smj"
  OFS=FS="\t"
  print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  print "<dictionary>"
  print "<section id=\"inc\">"
  qlines=""
}
function del_ar(ar) {
  for(i in ar) {
    delete ar[i]
  }
}

function output() {
  if(questionable) {
    for(l in lines) {
      qlines=qlines"\n"l
    }
    qlines=qlines"\n"
  }
  else {
    for(src in good) {
      for(trg in good[src]) {
        print "<e><p><l>"src"<s n=\""pos"\"/></l><r>"trg"<s n=\""pos"\"/></r></p></e>"
      }
    }
  }
}


/^ *#[+] if unmarked/{
  mostly="good"
}
/^ *#[@] if unmarked/{
  mostly="bad"
}
/^ *#/{
  next
}

!(mostly) {
  print "Please prepend the file with a comment on what the unmarked default is!"
  exit(1)
}

/^ *$/ {
	output()
  questionable=0
	del_ar(good)
	del_ar(lines)
	next
}

{
  lines[$0]++
}

/^[?-]/ {
  sub(/^[?-]/,"")
  questionable++
  next
}

/^[+]/ || (mostly=="good" && $1 ~ /^[^@?-]/){
  sub(/^[+]/,"")
  good[$1][$2]++
  next
}

/^[@]/ || (mostly=="bad" && $1 ~ /^[^+]/){
  sub(/^[@]/,"")
  bad[$1][$2]++
  next
}

END {
	output()
  print ""
  print "<!-- Bad suggestions, remove next time round: "
  for(src in bad) for(trg in bad[src]) print src" ::: "trg" ::: "pos
  print " -->"
  print ""
  print "<!-- Questionable suggestions, look more at: "
  print qlines
  print " -->"
  print "</section>"
  print "</dictionary>"
}
