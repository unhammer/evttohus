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
	../good-toktmx.sh $(LANG2) $(LANG1) | grep "^$*" |cut -f2 >$@
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


eval/alignments.ana.$(LANG1): alignments.merged eval/.d
	cut -f1 $< | bash -c "source ../../functions.sh; ana $(LANG1)" >$@
eval/alignments.ana.$(LANG2): alignments.merged eval/.d
	cut -f2 $< | bash -c "source ../../functions.sh; ana $(LANG2)" >$@


eval/alignments.lms.%.$(LANG1): eval/alignments.ana.%.$(LANG1)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@
eval/alignments.lms.%.$(LANG2): eval/alignments.ana.%.$(LANG2)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@

# These files are already named things like V.nob, but we do analysis
# and posgrep to make sure everything is comparable:
eval/fad.ana.%: ../../words-src-fad/% eval/.d
	bash -c "source ../../functions.sh; ana $*" <$< >$@
eval/fad.lms.%.$(LANG1): eval/fad.lms.%.$(LANG1)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@

eval-%: eval/alignments.lms.%.$(LANG1)  eval/alignments.lms.%.$(LANG2) eval/fad.lms.%.$(LANG1) eval/fad.lms.%.$(LANG2)
	head -10000 alignments.merged \
	  gawk -v pos=$* -v src=$(LANG1) -v trg=$(LANG2) -f eval.awk

%/.d:
	@test -d $* || mkdir $*
	@touch $@
.PRECIOUS: tmp/.d eval/.d

clean:
	rm -f words.$(LANG1)$(LANG2) words.$(LANG1) words.$(LANG2) corp.$(LANG1) corp.$(LANG2) lower.$(LANG1) lower.$(LANG2) cleaned.$(LANG1) cleaned.$(LANG2) cleaned.$(LANG1)_$(LANG2) tmp.alignments.*

reallyclean:
	rm -f alignments.merged alignments.merged.tmp

.PHONY: all clean reallyclean
