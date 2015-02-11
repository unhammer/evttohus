all: out/nobsmasme out/nobsmjsme

out/nobsmasme out/nobsmjsme: out/smesmj out/nobsma
	./pretty.sh

out/smesmj: words words-src-fad
	./sme2smjify.sh
	./decompound.sh sme smj

out/nobsma: words words-src-fad
	./decompound.sh nob sma

words words-src-fad:
	./dicts-to-tsv.sh



# The above goals depend on the corpus, but that takes forever … use
# this to re-make the full corpus:
corpus:
	./make-freq.sh sma corpus
	./make-freq.sh smj corpus
	./make-freq.sh nob corpus
	./make-freq.sh sme corpus

# Or to re-make just the frequency lists:
freq:
	./make-freq.sh sma
	./make-freq.sh smj
	./make-freq.sh nob
	./make-freq.sh sme


clean:
	rm -rf out tmp

.PHONY: corpus freq all clean

