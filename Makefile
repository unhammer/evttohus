# TODO: make -j2 doesn't seem to work with multiple targets?

DPOS=V N A
XPOS=V N A nonVNA
DECOMPBASES=$(patsubst %,%_decomp,$(DPOS))
LEXCBASES=$(patsubst %,%_lexc,$(XPOS))
XFSTBASES=$(patsubst %,%_xfst,$(XPOS))

DECOMPSMA=$(patsubst %,out/nobsma/%,$(DECOMPBASES))
DECOMPSMJ=$(patsubst %,out/smesmj/%,$(DECOMPBASES))
XIFIEDSMJ=$(patsubst %,out/smesmj/%,$(LEXCBASES)) \
          $(patsubst %,out/smesmj/%,$(XFSTBASES))

all: out/nobsmasme out/nobsmjsme

out/nobsmasme out/nobsmjsme: $(DECOMPSMA) $(DECOMPSMJ) $(XIFIEDSMJ)
	./pretty.sh

$(DECOMPSMA): words words-src-fad out/.d
	./decompound.sh nob sma

$(DECOMPSMJ): words words-src-fad out/.d
	./decompound.sh sme smj

$(XIFIEDSMJ): words words-src-fad out/.d
	./sme2smjify.sh

words words-src-fad: words/.d words-src-fad/.d
	./dicts-to-tsv.sh


words/%.V: words/% freq/forms.%
	./grab-lms-of-pos.sh $* V
words/%.N: words/% freq/forms.%
	./grab-lms-of-pos.sh $* N
words/%.A: words/% freq/forms.%
	./grab-lms-of-pos.sh $* A


freq/forms.% freq/lms.% freq/combined.%: freq/prepcorp.% freq/plaincorp.%
	./corp-to-freqlist.sh $*

freq/prepcorp.% freq/plaincorp.%: freq/.d # corpus
	./prep-corp.sh $*

apertium-sme-sma.sme-sma.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-sma/$@
apertium-sme-smj.sme-smj.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/nursery/apertium-sme-smj/$@
apertium-sme-nob.sme-nob.dix:
	svn export https://svn.code.sf.net/p/apertium/svn/trunk/apertium-sme-nob/$@

# The above goals depend on the corpus, but that takes forever … use
# this to re-make the full corpus:
corpus:
	bash -c "source functions.sh; convert_all sma"
	bash -c "source functions.sh; convert_all smj"
	bash -c "source functions.sh; convert_all nob"
	bash -c "source functions.sh; convert_all sme"

%/.d:
	test -d $* || mkdir $*
	touch $@
.PRECIOUS: freq/.d words/.d out/.d tmp/.d words/.d words-src-fad/.d

clean:
	rm -rf out tmp words words-src-fad

reallyclean: clean
	rm -rf freq

.PHONY: corpus allfreq all clean reallyclean

