
lexer.ml: lexer.mll
	ocamllex lexer.mll

lexer.cmo: lexer.ml parser.cmo
	ocamlc -c lexer.ml

r_ast.cmo: r_ast.ml
	ocamlc -c r_ast.ml

parser.mli parser.ml: parser.mly
	menhir --dump --explain parser.mly

parser.cmi: parser.mli r_ast.cmo
	ocamlc -c parser.mli

parser.cmo: parser.ml parser.cmi r_ast.cmo
	ocamlc -c parser.ml

absyn_generator: r_ast.cmo parser.cmo lexer.cmo
	ocamlc -o absyn_generator.ml

clean:
	rm -f *.cmi *.cmo lexer.ml parser.ml parser.mli parser.conflicts parser.automaton
    
