all: dbstag-tutorial.html

%.html: %.sgml
	db2html --nochunks $*.sgml > $@.tmp && mv $@.tmp $@
