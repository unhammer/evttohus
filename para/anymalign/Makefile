LANG1=nob
LANG2=sma

all: alignments.merged

anymalign/anymalign.py:
	git clone -b signal_handler https://github.com/unhammer/anymalign.git

# Don't delete intermediates:
.SECONDARY:

words.$(LANG1)$(LANG2):
	cat ../../words/$(LANG1)$(LANG2)/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)print $$1,$$i}' >$@
	cat ../../words/$(LANG2)$(LANG1)/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)if($$i!~/_SWE/)print $$i,$$1}' >>$@

words.$(LANG1): words.$(LANG1)$(LANG2)
	cut -f1 <$< >$@
words.$(LANG2): words.$(LANG1)$(LANG2)
	cut -f2 <$< >$@

corp.%: words.%
	../good-toktmx.sh $(LANG1) $(LANG2) | grep "^$*" |cut -f2 >$@
	cat words.$* >>$@

# such sparse data, just lowercase it all:
lower.%: corp.%
	perl -CSAD -wnpe '$$_=lc' <$< >$@

cleaned.$(LANG1)_$(LANG2): lower.$(LANG1) lower.$(LANG2)
	paste $^ | sort -u >$@
cleaned.$(LANG1): cleaned.$(LANG1)_$(LANG2)
	cut -f1 <$< >$@
cleaned.$(LANG2): cleaned.$(LANG1)_$(LANG2)
	cut -f2 <$< >$@

alignments.merged: cleaned.$(LANG1) cleaned.$(LANG2) anymalign/anymalign.py
	./run.sh cleaned.$(LANG1) cleaned.$(LANG2) > $@.tmp
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
