LANG1=nob
LANG2=sma

# If false, we include the gold set in the training material
DOEVAL=false

TARGETS=alignments.merged \
	eval/V.results.1k \
	eval/V.results.10k \
	eval/V.results.100k \
	eval/N.results.1k \
	eval/N.results.10k \
	eval/N.results.100k \
	eval/A.results.1k \
	eval/A.results.10k \
	eval/A.results.100k

all: $(TARGETS)

eval: all
	tail -n-5 eval/*.results.*

# TODO: cat words/nobsma/[^VNA]* > words/nobsma/nonVNA.tsv in
# order to eval this, though so few words there, not really important?
 # eval/nonVNA.results.1k \
 # eval/nonVNA.results.10k \
 # eval/nonVNA.results.100k

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
	../good-toktmx.sh $(LANG1)$(LANG2) $(DOEVAL) | grep "^$*" |cut -f2 >$@
	../good-toktmx.sh $(LANG2)$(LANG1) $(DOEVAL) | grep "^$*" |cut -f2 >$@
	if ! $(DOEVAL); then cat words.$* >>$@; fi # only unless evaluating

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
	mv $@.tmp $@


eval/alignments.ana.$(LANG1): alignments.merged eval/.d
	cut -f1 $< | bash -c "source ../../functions.sh; ana $(LANG1)" >$@
eval/alignments.ana.$(LANG2): alignments.merged eval/.d
	cut -f2 $< | bash -c "source ../../functions.sh; ana $(LANG2)" >$@


eval/alignments.lms.%.$(LANG1): eval/alignments.ana.$(LANG1)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@
eval/alignments.lms.%.$(LANG2): eval/alignments.ana.$(LANG2)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@

# These files are already named things like V.nob, but we still do
# analysis and posgrep to make sure everything is comparable:
eval/fad.ana.%.$(LANG1): ../../fadwords/%.$(LANG1) eval/.d
	bash -c "source ../../functions.sh; ana $(LANG1)" <$< >$@
eval/fad.lms.%.$(LANG1): eval/fad.ana.%.$(LANG1)
	bash -c "source ../../functions.sh; ana_to_forms_lms_of_pos $*" <$< >$@

eval/%.results.1k eval/%.results.10k eval/%.results.100k: eval/alignments.lms.%.$(LANG1) eval/alignments.lms.%.$(LANG2) eval/fad.lms.%.$(LANG1) ../../words/$(LANG1)$(LANG2)/%.tsv
	for h in 1000 10000 100000; do \
	  k=`echo $$h|sed 's/000$$/k/'`; \
	  head -$$h alignments.merged \
	  | gawk -v srclmf=eval/alignments.lms.$*.$(LANG1) \
	         -v trglmf=eval/alignments.lms.$*.$(LANG2) \
	         -v fadlmf=eval/fad.lms.$*.$(LANG1) \
	         -v transf=../../words/$(LANG1)$(LANG2)/$*.tsv \
	         -f eval.awk >eval/$*.results.$$k; \
	done

%/.d:
	@test -d $* || mkdir $*
	@touch $@
.PRECIOUS: tmp/.d eval/.d alignments.merged

clean:
	rm -f words.$(LANG1)$(LANG2) words.$(LANG1) words.$(LANG2) corp.$(LANG1) corp.$(LANG2) lower.$(LANG1) lower.$(LANG2) cleaned.$(LANG1) cleaned.$(LANG2) cleaned.$(LANG1)_$(LANG2) tmp.alignments.*
	rm -rf tmp eval

reallyclean: clean
	rm -f alignments.merged alignments.merged.tmp

.PHONY: all eval clean reallyclean
