all: spell.native

CFLAGS=
#CFLAGS=-cflags -g

spell.native: spell.ml dawg.ml _tags
	ocamlbuild $(CFLAGS) -use-ocamlfind -pkg batteries -pkg uutf -pkg uucp $< $@

clean:
	rm -rf _build spell.native
