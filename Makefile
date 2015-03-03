DPOS=V N A
XPOS=V N A nonVNA
DECOMPBASES=$(patsubst %,%_decomp,$(DPOS))
PRECOMPBASES=$(patsubst %,%_precomp,$(DPOS))
LEXCBASES=$(patsubst %,%_lexc,$(XPOS))
XFSTBASES=$(patsubst %,%_xfst,$(XPOS))

DECOMPSMA=$(patsubst %,out/nobsma/%,$(DECOMPBASES)) \
          $(patsubst %,out/nobsma/%,$(PRECOMPBASES))

DECOMPSMJ=$(patsubst %,out/smesmj/%,$(DECOMPBASES)) \
          $(patsubst %,out/nobsmj/%,$(DECOMPBASES)) \
          $(patsubst %,out/smesmj/%,$(PRECOMPBASES)) \
          $(patsubst %,out/nobsmj/%,$(PRECOMPBASES))

XIFIEDSMJ=$(patsubst %,out/smesmj/%,$(LEXCBASES)) \
          $(patsubst %,out/smesmj/%,$(XFSTBASES))

PARASMA=freq/nobsma.lemmas.ids freq/smesma.lemmas.ids
PARASMJ=freq/nobsmj.lemmas.ids freq/smesmj.lemmas.ids

all: out/nobsmasme out/nobsmjsme

spellms: $(patsubst %,freq/slms.%.smj,$(DPOS)) \
         $(patsubst %,freq/slms.%.sma,$(DPOS)) 

out/nobsmasme: $(DECOMPSMA) out/nobsmasme/.d tmp/nobsmasme/.d tmp/nobsma/.d words/all.sma $(PARASMA)
	./canonicalise.sh nobsma
out/nobsmjsme: $(DECOMPSMJ) $(XIFIEDSMJ) out/nobsmjsme/.d tmp/nobsmjsme/.d tmp/smesmj/.d tmp/nobsmj/.d words/all.smj $(PARASMJ)
	./canonicalise.sh smesmj
	./canonicalise.sh nobsmj

out/%/V_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/V.tsv
	./decompound.sh $* V
out/%/N_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/N.tsv
	./decompound.sh $* N
out/%/A_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/A.tsv
	./decompound.sh $* A

out/%/V_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/precomp_V.tsv
	./decompound.sh $* V precomp
out/%/N_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/precomp_N.tsv
	./decompound.sh $* N precomp
out/%/A_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/precomp_A.tsv
	./decompound.sh $* A precomp

out/%/V_lexc out/%/N_lexc out/%/A_lexc out/%/nonVNA_lexc out/%/V_xfst out/%/N_xfst out/%/A_xfst out/%/nonVNA_xfst: fadwords/all.sme out/%/.d
	./sme2smjify.sh


# Run anymalign-pre, then cd para/anymalign and make:
anymalign-pre: fadwords/all.nob words/all.nob words/all.sma
# Afterwards, go back here and make anymalign-post && make:
anymalign-post: out/nobsma/V_anymalign out/nobsma/N_anymalign out/nobsma/A_anymalign

# Just use eval results from anymalign for now since these already
# have the "fad" field on stuff that's in fad:
out/nobsma/%_anymalign: para/anymalign/eval/%.results.100k
	awk -F'\t' '$$4=="fad"' $< | sort -nr | cut -f5-6 | grep -v '\*' > $@


# "Normalised" TSV versions of dictionaries from $GTHOME/words/dicts:
words/%/V.tsv words/%/N.tsv words/%/A.tsv: words/%/.d
	bash -c "source functions.sh; cd words; dir2tsv '' '$*'"

words/%.sme: words/smenob/%.tsv words/nobsme/%.tsv \
           words/smesmj/%.tsv words/smjsme/%.tsv \
           words/smasme/%.tsv # no smesma/src
	bash -c "source functions.sh; cd words; mono_from_bi sme $*" > $@
words/%.nob: words/nobsmj/%.tsv words/smjnob/%.tsv \
           words/nobsma/%.tsv words/smanob/%.tsv \
           words/nobsme/%.tsv words/smenob/%.tsv
	bash -c "source functions.sh; cd words; mono_from_bi nob $*" > $@
words/%.sma: words/smanob/%.tsv words/nobsma/%.tsv \
           words/smasme/%.tsv # no smesma/src
	bash -c "source functions.sh; cd words; mono_from_bi sma $*" > $@
words/%.smj: words/smjnob/%.tsv words/nobsmj/%.tsv \
             words/smjsme/%.tsv words/smesmj/%.tsv
	bash -c "source functions.sh; cd words; mono_from_bi smj $*" > $@

words/nonVNA.%: words/V.% words/N.% words/A.%
	bash -c "source functions.sh; cd words; mono_from_bi $* nonVNA" > $@
words/all.%: words/nonVNA.%
	bash -c "source functions.sh; cd words; mono_from_bi $* ''" > $@



fadwords/%/V.tsv fadwords/%/N.tsv fadwords/%/A.tsv: fadwords/%/.d
	bash -c "source functions.sh; cd fadwords; dir2tsv '[@src=\"fad\"]' '$*'"
	@touch fadwords/$*/Pron_$*.tsv # just to stop canonicalise.sh from complaining

fadwords/%.sme: fadwords/smenob/%.tsv fadwords/nobsme/%.tsv
	bash -c "source functions.sh; cd fadwords; mono_from_bi sme $*" > $@
fadwords/%.nob: fadwords/smenob/%.tsv fadwords/nobsme/%.tsv
	bash -c "source functions.sh; cd fadwords; mono_from_bi nob $*" > $@

fadwords/nonVNA.%: fadwords/V.% fadwords/N.% fadwords/A.%
	bash -c "source functions.sh; cd fadwords; mono_from_bi $* nonVNA" > $@
fadwords/all.%: fadwords/nonVNA.%
	bash -c "source functions.sh; cd fadwords; mono_from_bi $* ''" > $@


# Alignment of decompounded parts of words/dicts:
words/%/precomp_V.tsv: words/%/V.tsv
	./precomp.sh $* V > $@
words/%/precomp_N.tsv: words/%/N.tsv
	./precomp.sh $* N > $@
words/%/precomp_A.tsv: words/%/A.tsv
	./precomp.sh $* A > $@



# For speller:
freq/slms.V.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* V" >$@
freq/slms.N.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* N" >$@
freq/slms.A.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* A" >$@


# Parallel texts:
freq/%.sents:
	para/good-toktmx.sh $* false >$@

freq/nobsma.sents.ids: freq/nobsma.sents freq/smanob.sents
	para/id-uniq-sents.sh $^ >$@
freq/smesma.sents.ids: freq/smesma.sents freq/smasme.sents
	para/id-uniq-sents.sh $^ >$@
freq/nobsmj.sents.ids: freq/nobsmj.sents freq/smjnob.sents
	para/id-uniq-sents.sh $^ >$@
freq/smesmj.sents.ids: freq/smesmj.sents freq/smjsme.sents
	para/id-uniq-sents.sh $^ >$@

freq/%_nob.ana: freq/%.sents.ids
	para/ana-sents.sh nob <$< >$@
freq/%_sma.ana: freq/%.sents.ids
	para/ana-sents.sh sma <$< >$@
freq/%_sme.ana: freq/%.sents.ids
	para/ana-sents.sh sme <$< >$@
freq/%_smj.ana: freq/%.sents.ids
	para/ana-sents.sh smj <$< >$@

freq/nobsma.lemmas.ids: freq/nobsma_nob.ana freq/nobsma_sma.ana
	para/join-lemmas-on-ids.sh $^ >$@
freq/smesma.lemmas.ids: freq/smesma_sme.ana freq/smesma_sma.ana
	para/join-lemmas-on-ids.sh $^ >$@
freq/nobsmj.lemmas.ids: freq/nobsmj_nob.ana freq/nobsmj_smj.ana
	para/join-lemmas-on-ids.sh $^ >$@
freq/smesmj.lemmas.ids: freq/smesmj_sme.ana freq/smesmj_smj.ana
	para/join-lemmas-on-ids.sh $^ >$@


# Corpora/frequency lists:
freq/forms.% freq/lms.% freq/combined.%: freq/prepcorp.%.xz freq/plaincorp.%.xz
	./corp-to-freqlist.sh $*

freq/prepcorp.%.xz freq/plaincorp.%.xz: freq/.d # corpus
	./prep-corp.sh $*

# The above goals depend on the corpus, but that takes forever … use
# this to re-make the full corpus:
corpus:
	bash -c "source functions.sh; convert_all sma"
	bash -c "source functions.sh; convert_all smj"
	bash -c "source functions.sh; convert_all nob"
	bash -c "source functions.sh; convert_all sme"

# "make stats" will show corpus coverage
stats: all tmp/.d
	./coverage.sh


# Not used yet:
apertium-sme-sma.sme-sma.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-sma/$@
apertium-sme-smj.sme-smj.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-smj/$@
apertium-sme-nob.sme-nob.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/trunk/apertium-sme-nob/$@


# Creating directories:
words/%/.d: words/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
fadwords/%/.d: fadwords/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
out/%/.d: out/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
tmp/%/.d: tmp/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
%/.d:
	@test -d $(@D) || mkdir $(@D)
	@touch $@
.PRECIOUS: freq/.d words/.d out/.d tmp/.d words/.d fadwords/.d out/nobsmasme/.d out/nobsmjsme/.d tmp/nobsmasme/.d tmp/nobsmjsme/.d

# Actually, don't delete any intermediates:
.SECONDARY:


# Cleaning:
clean:
	rm -rf out tmp words fadwords

reallyclean: clean
	rm -rf freq

.PHONY: corpus all spellms clean reallyclean
