LANG1=nob
LANG2=sma

all: alignments.merged

anymalign/anymalign.py:
	git clone -b signal_handler https://github.com/unhammer/anymalign.git

# Don't delete intermediates:
.SECONDARY:

words:
	cat ../../words/nobsma/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++){print "nob",$$1"\nsma",$$i"\n"}}' >$@
	cat ../../words/smanob/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)if($$i!~/_SWE/){print "nob",$$i"\nsma",$$1"\n"}}' >>$@

corp.%: words
	../good-toktmx.sh $(LANG1) $(LANG2) | grep "^$*" |cut -f2 >$@
	grep "^$*" words|cut -f2 >>$@

# such sparse data, just lowercase it all:
lower.%: corp.%
	perl -CSAD -wnpe '$$_=lc' <$< >$@


alignments.merged: lower.$(LANG1) lower.$(LANG2) anymalign/anymalign.py
	./run.sh lower.$(LANG1) lower.$(LANG2) > $@.tmp
	cp $@.tmp $@
# make of course notices any signal and deletes alignments.merged,
# thus the tmp file. Could run anymalign with a timeout, but meh

%/.d:
	@test -d $* || mkdir $*
	@touch $@
.PRECIOUS: tmp/.d

clean:
	rm tmp.alignments.*

reallyclean:
	rm alignments.merged

.PHONY: all clean reallyclean
