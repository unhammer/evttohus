all: spell.native comp.native

CFLAGS=
#CFLAGS=-cflags -g

spell.native: spell.ml dawg.ml _tags
	ocamlbuild $(CFLAGS) -use-ocamlfind -pkg batteries -pkg uutf -pkg uucp $< $@

comp.native: comp.ml dawg.ml _tags
	ocamlbuild $(CFLAGS) -use-ocamlfind -pkg batteries $< $@

clean:
	rm -rf _build spell.native
