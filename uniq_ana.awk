#!/usr/bin/env gawk -f
# -*- indent-tabs-mode: nil; c-basic-offset: 2; -*-

BEGIN{
  OFS=FS="\t"
}

function print_cohorts () {
  if(length(cohort[shortest])!=0) {
    for(r in cohort[shortest]) {
      print r
    }
  }
  for(n_parts in cohort) {
	  if(length(cohort[n_parts])!=0) {
		  for(r in cohort[n_parts]) {
			  delete cohort[n_parts][r]
		  }
	  }
  }
  shortest=99999
}

$1!=form {
  print_cohorts()
}
END {
  print_cohorts()
}

{
  form=$1
  cohort[NF][$0]++
}

NF < shortest {
  shortest=NF
}

