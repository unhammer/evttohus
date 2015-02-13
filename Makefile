all: out/nobsmasme out/nobsmjsme $(LMS) $(FREQ)

FREQ=freq/forms.sma freq/forms.nob freq/forms.sme freq/forms.smj  
LMS=words/sma.V words/sma.N words/sma.A words/smj.V words/smj.N words/smj.A

out/nobsmasme out/nobsmjsme: out/smesmj out/nobsma
	./pretty.sh

out/smesmj: words words-src-fad out/.d
	./sme2smjify.sh
	./decompound.sh sme smj

out/nobsma: words words-src-fad out/.d
	./decompound.sh nob sma

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

