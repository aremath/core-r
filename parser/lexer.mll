(*
  Adapted from: https://github.com/antlr/grammars-v4/blob/master/r/R.g4
*)

{
  let incr_line_count : Lexing.lexbuf -> unit =
    fun lexbuf ->
      let
        pos = lexbuf.Lexing.lex_curr_p
      in
        lexbuf.Lexing.lex_curr_p <- {
          pos with
            Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
            Lexing.pos_bol = pos.Lexing.pos_cnum;
        }

  let filter_numeric : string -> string =
    fun str ->
      let
        len = String.length str
      in
        if len = 0
          then ""
          else if String.contains "iL" (String.get str (len - 1))
            then String.sub str 0 (len - 1)
            else str
}

let hex_digit =
  ['0'-'9' 'a'-'f' 'A'-'F']

let hex =
  '0' ['x' 'X'] hex_digit+

let digit =
  ['0'-'9']

let int =
  digit+ 'L'?

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

let alpha =
    ['a'-'z' 'A'-'Z']

let ident =
    '.' (alpha | '_' | '.') (alpha | digit | '_' | '.')*
  | alpha (alpha | digit | '_' | '.')*

let qual_ident =
  ident ("::" | ":::") ident

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
  | ":="        { COLONEQ }

  (* Keywords *)
  | "function"  { FUNCTION }
  | "return"    { RETURN }
  | "if"        { IF }
  | "for"       { FOR }
  | "while"     { WHILE }
  | "repeat"    { REPEAT }
  | "next"      { NEXT }
  | "break"     { BREAK }

  (* Native values *)
  | "NULL"      { NULL }
  | "NA"        { NA }
  | "Inf"       { INFINITY }
  | "NaN"       { NAN }
  | "TRUE"      { TRUE }
  | "FALSE"     { FALSE }

  (* Valued tokens *)
  | qual_ident  { IDENT (Lexing.lexeme lexbuf) }
  | user_op     { USEROP (Lexing.lexeme lexbuf) }
  | string      { STRING (Lexing.lexeme lexbuf) }
  | hex         { INT (int_of_string (Lexing.lexeme lexbuf)) }
  | int         { INT (int_of_string
                        (filter_numeric (Lexing.lexeme lexbuf))) }
  | float       { FLOAT (float_of_string (Lexing.lexeme lexbuf)) }
  | complex     { COMPLEX (float_of_string
                            (filter_numeric (Lexing.lexeme lexbuf))) }

  (* To be skipped *)
  | comment     { tokenize lexbuf }
  | newline     { incr_line_count; tokenize lexbuf; }
  | whitespace  { tokenize lexbuf }

  (* Everybody's favorite thing that's technically not a char some times *)
  | eof         { EOF }


