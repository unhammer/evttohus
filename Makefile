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

all: out/nobsmasme out/nobsmjsme

spellms: $(patsubst %,freq/slms.%.smj,$(DPOS)) \
         $(patsubst %,freq/slms.%.sma,$(DPOS)) 

out/nobsmasme: $(DECOMPSMA) out/nobsmasme/.d tmp/.d tmp/nobsmasme/.d
	./canonicalise.sh nobsma
out/nobsmjsme: $(DECOMPSMJ) $(XIFIEDSMJ) out/nobsmjsme/.d tmp/.d tmp/nobsmjsme/.d
	./canonicalise.sh smesmj
	./canonicalise.sh nobsmj

out/%/V_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/V.tsv
	./decompound.sh $* V
out/%/N_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/N.tsv
	./decompound.sh $* N
out/%/A_decomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/A.tsv
	./decompound.sh $* A

out/%/V_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/V_precomp.tsv
	./decompound.sh $* V precomp
out/%/N_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/N_precomp.tsv
	./decompound.sh $* N precomp
out/%/A_precomp: fadwords/all.sme fadwords/all.nob out/%/.d words/%/A_precomp.tsv
	./decompound.sh $* A precomp

out/%/V_lexc out/%/N_lexc out/%/A_lexc out/%/nonVNA_lexc out/%/V_xfst out/%/N_xfst out/%/A_xfst out/%/nonVNA_xfst: fadwords/all.sme out/%/.d
	./sme2smjify.sh


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


words/%/V_precomp.tsv: words/%/V.tsv
	./precomp.sh $* V > $@
words/%/N_precomp.tsv: words/%/N.tsv
	./precomp.sh $* N > $@
words/%/A_precomp.tsv: words/%/A.tsv
	./precomp.sh $* A > $@


# For speller:
freq/slms.V.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* V" >$@
freq/slms.N.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* N" >$@
freq/slms.A.%: words/all.% freq/forms.%
	bash -c "source functions.sh; all_lms_of_pos $* A" >$@


freq/forms.% freq/lms.% freq/combined.%: freq/prepcorp.%.xz freq/plaincorp.%.xz
	./corp-to-freqlist.sh $*

freq/prepcorp.%.xz freq/plaincorp.%.xz: freq/.d # corpus
	./prep-corp.sh $*

apertium-sme-sma.sme-sma.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-sma/$@
apertium-sme-smj.sme-smj.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-smj/$@
apertium-sme-nob.sme-nob.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/trunk/apertium-sme-nob/$@

stats: all tmp/.d
	./coverage.sh

# The above goals depend on the corpus, but that takes forever … use
# this to re-make the full corpus:
corpus:
	bash -c "source functions.sh; convert_all sma"
	bash -c "source functions.sh; convert_all smj"
	bash -c "source functions.sh; convert_all nob"
	bash -c "source functions.sh; convert_all sme"

words/%/.d: words/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
fadwords/%/.d: fadwords/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
out/%/.d: out/.d
	@test -d $(@D) || mkdir $(@D)
	@touch $@
%/.d:
	@test -d $(@D) || mkdir $(@D)
	@touch $@
.PRECIOUS: freq/.d words/.d out/.d tmp/.d words/.d fadwords/.d out/nobsmasme/.d out/nobsmjsme/.d tmp/nobsmasme/.d tmp/nobsmjsme/.d

# Actually, don't delete any intermediates:
.SECONDARY:

clean:
	rm -rf out tmp words fadwords

reallyclean: clean
	rm -rf freq

.PHONY: corpus all spellms clean reallyclean
