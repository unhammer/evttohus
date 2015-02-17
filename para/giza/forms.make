LANG1=nob
LANG2=sma

# Where you checked out moses and mgiza:
MGIZAPP=$(HOME)/src/mgiza/mgizapp
MOSES=$(HOME)/src/mosesdecoder

all: alignwork/model/phrase-table.gz
	@echo
	@echo Phrase table sample:
	@zcat $< | head
	@echo
	@echo Phrase table length:
	@zcat $< | wc -l

# Don't delete intermediates:
.SECONDARY:

words:
	cat ../../words/nobsma/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++){print "nob",$$1"\nsma",$$i"\n"}}' >$@
	cat ../../words/smanob/*.tsv | awk 'BEGIN{OFS=FS="\t"} {for(i=2;i<=NF;i++)if($$i!~/_SWE/){print "nob",$$i"\nsma",$$1"\n"}}' >>$@

corp.%: words
	../good-toktmx.sh $(LANG1) $(LANG2) | grep "^$*" |cut -f2 >$@
	grep "^$*" words|cut -f2|sed 's/$$/ ./' >>$@

# TODO:
$(MOSES)/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.nob: $(MOSES)/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.fi
	cat $< >$@
$(MOSES)/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.sma: $(MOSES)/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.sv
	cat $< >$@

tok.%: corp.% $(MOSES)/scripts/share/nonbreaking_prefixes/nonbreaking_prefix.%
	$(MOSES)/scripts/tokenizer/tokenizer.perl -l $* <$< >$@

truecase-model.%: tok.%
	$(MOSES)/scripts/recaser/train-truecaser.perl --model $@ --corpus $<

true.%: tok.% truecase-model.%
	$(MOSES)/scripts/recaser/truecase.perl --model truecase-model.$* <$< >$@

# such sparse data, just lowercase it all:
lower.%: tok.%
	perl -CSAD -wnpe '$$_=lc' <$< >$@


# Pattern is just "d" here; pattern rules are the only *safe* way to
# specify multiple outputs in make
cleane%.$(LANG1) cleane%.$(LANG2): lower.$(LANG1) lower.$(LANG2)
	$(MOSES)/scripts/training/clean-corpus-n.perl lower $(LANG1) $(LANG2) cleaned 1 80


arpa.%: ../../freq/plaincorp.%.xz lmwork/.d
	xzcat $< >$@.plain
	$(MOSES)/scripts/tokenizer/tokenizer.perl -l $* <$@.plain >$@.tok
	perl -CSAD -wnpe '$$_=lc' < $@.tok >$@.lower
	$(MOSES)/bin/lmplz -o 3 -S 70% T lmwork <$@.lower >$@
	@rm -f $@.plain $@.lower $@.tok

blm.%: arpa.%
	$(MOSES)/bin/build_binary $< $@

alignwork/model/phrase-table.gz: cleaned.$(LANG1) cleaned.$(LANG2) blm.$(LANG2) alignwork/.d alignwork/mgizapp/.d
	@cp $(MGIZAPP)/inst/scripts/* $(MGIZAPP)/inst/bin/* alignwork/mgizapp/
	@echo "GIZA"
	$(MOSES)/scripts/training/train-model.perl \
	-root-dir $(abspath alignwork) \
	-corpus cleaned -f $(LANG1) -e $(LANG2) \
	-alignment grow-diag-final-and \
	-reordering msd-bidirectional-fe \
	-lm 0:3:$(abspath blm.$(LANG2)):8 \
	-cores 3 \
	-mgiza -mgiza-cpus 3 \
	-external-bin-dir $(abspath alignwork/mgizapp)

%/.d:
	@test -d $* || mkdir $*
	@touch $@
.PRECIOUS: lmwork/.d alignwork/.d

clean:
	rm -f blm.$(LANG1) blm.$(LANG2) arpa.$(LANG1) arpa.$(LANG2) truecase-model.$(LANG1) truecase-model.$(LANG2) true.$(LANG1) true.$(LANG2) tok.$(LANG1) tok.$(LANG2) cleaned.$(LANG1) cleaned.$(LANG2) corp.$(LANG1) corp.$(LANG2) lower.$(LANG1) lower.$(LANG2) words
	rm -rf lmwork alignwork

.PHONY: all clean
