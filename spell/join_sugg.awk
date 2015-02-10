#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

# Assuming stdin is a file of:
#smeinput	smjified
#
# and the argument -vsuggs is a file of:
#smjified	smjsuggestion1	smjsuggestion2	…
#
# this script will join the smjified fields to give
#smeinput	smjsuggestion1
#smeinput	smjsuggestion2
#smeinput	…
#
# (throwing away the intermediate smjified)

BEGIN{
	OFS=FS="\t"
  while(getline<suggs) {
    for(i=2;i<=NF;i++) {
      sugg[$1][$i]++
    }
  }
}

{
  for(i=2;i<=NF;i++) {
    if($i in sugg) {
      for(s in sugg[$i]) {
        print $1,s
      }
    }
  }
}
