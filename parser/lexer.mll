(*
  Adapted from: https://github.com/antlr/grammars-v4/blob/master/r/R.g4
*)

{
  let incr_line_count lexbuf =
    let
      pos = lexbuf.Lexing.lex_curr_p
    in
      lexbuf.Lexing.lex_curr_p <- {
        pos with
          Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
          Lexing.pos_bol = pos.Lexing.pos_cnum;
      }
}

let hex_digit =
  ['0'-'9' 'a'-'f' 'A'-'F']

let hex =
  '0' ['x' 'X'] hex_digit+

let digit =
  ['0'-'9']

let int =
  digit+

let exp =
  ['e' 'E'] ['+' '-']? int

let float =
    digit+ '.' digit* exp?
  | digit+ exp?
  | '.' digit+ exp?

let complex =
    int 'i'
  | float 'i'

let oct_esc =
    '\\' ['0'-'3'] ['0'-'7'] ['0'-'7']
  | '\\' ['0'-'7'] ['0'-'7']
  | '\\' ['0'-'7']

let hex_esc =
  '\\' hex+

let uni_esc =
    '\\' 'u' hex hex hex hex
  | '\\' 'u' '{' hex hex hex hex '}'

let esc =
    '\\' ['a' 'b' 't' 'n' 'f' 'r' 'v' '\\']
  | oct_esc
  | hex_esc
  | uni_esc

let string =
    '"' (esc | [^ '"'])* '"'
  | '\'' (esc | [^ '\''])* '\''
  | '`' (esc | [^ '`'])* '`'

let letter =
    ['a'-'z' 'A'-'Z']

let ident =
    '.' (letter | '_' | '.') (letter | digit | '_' | '.')*
  | letter (letter | digit | '_' | '.')*

(* Missing the %in% matring operator *)
let user_op =
  '%' [^ '/' '*' 'o' 'x']+ '%'

let newline =
    '\n'
  | '\r'
  | '\r' '\n'

let comment =
  '#' _* newline

let whitespace =
  [' ' '\t']


(* Parsing *)
rule tokenize = parse
  (* Delimiters *)
  | "("         { LPAREN }
  | ")"         { RPAREN }

  | "["         { LBRACKET }
  | "]"         { RBRACKET }

  | "{"         { LBRACE }
  | "}"         { RBRACE }

  (* Operators (cf 3.1.4) *)
  | "-"         { MINUS }
  | "+"         { PLUS }
  | "!"         { UNOT }
  | "~"         { TILDE }
  | "?"         { HELP }
  | ":"         { COLON }
  | "*"         { MULT }
  | "/"         { DIV }
  | "^"         { EXP }
  | "%%"        { MODULUS }
  | "%/%"       { INTDIV }
  | "%*%"       { MATRIXMULT }
  | "%o%"       { OUTERPROD }
  | "%x%"       { KRONECKERPROD }
  | "<"         { LT }
  | ">"         { GT }
  | "=="        { EQ }
  | ">="        { GE }
  | "<="        { LE }
  | "&"         { ANDVEC }
  | "&&"        { ANDNOVEC }
  | "|"         { ORVEC }
  | "||"        { ORNOVEC }
  | "<-"        { LASSIGN }
  | "->"        { RASSIGN }
  | "$"         { LISTSUBSET }

  (* Additional operators (cf 10.4.2) *)
  | "::"        { NAMESPACE }
  | "@"         { ATTRIBUTE }
  | "<<-"       { LSUPASSIGN }
  | "->>"       { RSUPASSIGN }
  | "="         { ASSIGN }

  (* Were not listed but likely relevant *)
  | ";"         { SEMICOLON }

  (* Keywords *)
  | "function"  { FUNCTION }
  | "return"    { RETURN }
    (* These are stored as function calls (cf 10.4.5)
      | "if"        { IF }
      | "for"       { FOR }
      | "while"     { WHILE }
      | "repeat"    { REPEAT }
      | "next"      { NEXT }
      | "break"     { BREAK }
    *)

  (* Native values *)
  | "NULL"      { NULL }
  | "NA"        { NA }
  | "Inf"       { INFINITY }
  | "NaN"       { NAN }
  | "TRUE"      { TRUE }
  | "FALSE"     { FALSE }

  (* Valued tokens *)
  | ident       { IDENT (Lexing.lexeme lexbuf) }
  | user_op     { USEROP (Lexing.lexeme lexbuf) }
  | string      { STRING (Lexing.lexeme lexbuf) }
  | hex         { INT (int_of_string (Lexing.lexeme lexbuf)) }
  | int         { INT (int_of_string (Lexing.lexeme lexbuf)) }
  | float       { FLOAT (float_of_string (Lexing.lexeme lexbuf)) }
  | complex     { COMPLEX (let
                             yytext = Lexing.lexeme lexbuf
                             yylen = String.length yytext
                           in
                             if yylen < 2
                               then 0
                               else String.sub yytext 0 (yylen - 1)) }

  (* To be skipped *)
  | comment     { tokenize lexbuf }
  | newline     { incr_line_count; tokenize lexbuf; }
  | whitespace  { tokenize lexbuf }

  (* Everybody's favorite thing that's technically not a char some times *)
  | eof         { EOF }


