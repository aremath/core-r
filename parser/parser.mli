type token =
  | LPAREN
  | RPAREN
  | LBRACKET
  | RBRACKET
  | LBRACE
  | RBRACE
  | MINUS
  | PLUS
  | BANG
  | TILDE
  | HELP
  | COLON
  | MULT
  | DIV
  | EXP
  | MODULUS
  | INTDIV
  | MATRIXMULT
  | OUTERPROD
  | KRONECKERPROD
  | MATCH
  | LT
  | GT
  | EQEQ
  | NEQ
  | GE
  | LE
  | ANDVEC
  | ANDNOVEC
  | ORVEC
  | ORNOVEC
  | LASSIGN
  | RASSIGN
  | LISTSUBSET
  | SEMICOLON
  | COLONEQ
  | DOT3
  | COLON2
  | COLON3
  | ATTRIBUTE
  | LSUPASSIGN
  | RSUPASSIGN
  | EQASSIGN
  | FUNCTION
  | RETURN
  | IF
  | FOR
  | WHILE
  | REPEAT
  | NEXT
  | BREAK
  | NULL
  | NA
  | INFINITY
  | NAN
  | TRUE
  | FALSE
  | IDENT of (string)
  | USEROP of (string)
  | STRING of (string)
  | INT of (int)
  | FLOAT of (float)
  | COMPLEX of (float)
  | COMMA
  | EOF

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> expr
