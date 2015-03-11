#!/bin/bash

# Meant to run after canonicalise.sh (which creates files named
# out/${dir}/*_kintel with the candidates where the nob word was in
# Kintel).

for pos in V N A nonVNA; do
    test -f out/nobsmj_${pos}_kintel || test -f out/smesmj_${pos}_kintel || continue
    cat out/*smj_${pos}_kintel | sort -u \
        | gawk -v dict=<(cat words/nobsmj/${pos}*.tsv) '
        BEGIN{
          OFS=FS="\t"
          while(getline<dict) for(i=2;i<=NF;i++) kintel[$1][$i]++
        }
        function endblock() {
          if(prev in kintel) {
            for(trg in kintel[prev]) {
              if(!(prev in seen && trg in seen[prev])) {
                print "+"prev,trg
              }
            }
          }
        }
        $1 != prev { endblock() }
        END { endblock() }
        prev && $1 != prev { print "" }
        {
          if($1 in seen && $2 in seen[$1] && $3 in seen[$1][$2]) {
            next
          }
          if($1 in kintel && $2 in kintel[$1]) {
            print "+"$0
          }
          else {
            print
          }
          prev=$1
          seen[prev][$2][$3]++
        }
        ' > out/nobsmjsme/${pos}_kintel
done
