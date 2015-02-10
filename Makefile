all:
	./sme2smjify.sh
	./decompound.sh nob sma
	./decompound.sh sme smj

corpus:
	./make-freq.sh sma corpus
	./make-freq.sh smj corpus
	./make-freq.sh nob corpus
	./make-freq.sh sme corpus

# Just the frequency lists:
freq:
	./make-freq.sh sma
	./make-freq.sh smj
	./make-freq.sh nob
	./make-freq.sh sme

.PHONY: corpus freq all
