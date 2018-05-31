
(* The type of tokens. *)

type token = 
  | WHILE
  | USEROP of (string)
  | TRUE
  | TILDE
  | STRING of (string)
  | SEMICOLON
  | RSUPASSIGN
  | RPAREN
  | RETURN
  | REPEAT
  | RBRACKET
  | RBRACE
  | RASSIGN
  | PLUS
  | OUTERPROD
  | ORVEC
  | OR
  | NULL
  | NEXT
  | NEQ
  | NAN
  | NA
  | MULT
  | MODULUS
  | MINUS
  | MATRIXMULT
  | MATCH
  | LT
  | LSUPASSIGN
  | LPAREN
  | LISTSUBSET
  | LE
  | LBRACKET
  | LBRACE
  | LASSIGN
  | KRONECKERPROD
  | INTDIV
  | INT of (int)
  | INFINITY
  | IF
  | IDENT of (string)
  | HELP
  | GT
  | GE
  | FUNCTION
  | FOR
  | FLOAT of (float)
  | FALSE
  | EXP
  | EQEQ
  | EQASSIGN
  | EOF
  | DOT3
  | DIV
  | COMPLEX of (float)
  | COMMA
  | COLONEQ
  | COLON3
  | COLON2
  | COLON
  | BREAK
  | BANG
  | ATTRIBUTE
  | ANDVEC
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (expr)
