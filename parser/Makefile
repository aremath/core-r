
lexer.ml: lexer.mll
	ocamllex lexer.mll

lexer.cmo: lexer.ml parser.cmo
	ocamlc -c lexer.ml

rast.cmo: rast.ml
	ocamlc -c rast.ml

parser.mli parser.ml: parser.mly
	menhir --dump --explain parser.mly

parser.cmi: parser.mli rast.cmo
	ocamlc -c parser.mli

parser.cmo: parser.ml parser.cmi rast.cmo
	ocamlc -c parser.ml

clean:
	rm -f *.cmi *.cmo lexer.ml parser.ml parser.mli parser.conflicts parser.automaton
    
