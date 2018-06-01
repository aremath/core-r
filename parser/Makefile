
lexer.ml: lexer.mll
	ocamllex lexer.mll

lexer.cmo: lexer.ml parser.cmo
	ocamlc -c lexer.ml

rast.cmo: rast.ml
	ocamlc -c rast.ml

parser.mli parser.ml: parser.mly
	menhir --dump --explain parser.mly

parser.cmi: rast.cmo parser.mli
	ocamlc -c parser.mli

parser.cmo: rast.cmo parser.ml parser.cmi
	ocamlc -c parser.ml

absyn_generator: rast.cmo parser.cmo lexer.cmo
	ocamlc -o agen rast.cmo parser.cmo lexer.cmo absyn_generator.ml
clean:
	rm -f *.cmi *.cmo *.cmx *.o lexer.ml parser.ml parser.mli parser.conflicts parser.automaton
    
