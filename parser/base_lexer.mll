(*
  Adapted from:
    https://github.com/wch/r-source/blob/trunk/src/main/gram.y 
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


let na =
    "NA"
  | "NA_integer_"
  | "NA_real_"
  | "NA_character_"
  | "NA_complex_"


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

let symbol =
    '.' (alpha | '_' | '.') (alpha | digit | '_' | '.')*
  | alpha (alpha | digit | '_' | '.')*

(* Missing the %in% matring operator *)
let userop =
  '%' [^ '/' '*' 'o' 'x']+ '%'

let newline =
    '\n'
  | '\r'
  | '\r' '\n'

let comment =
  '#' _* newline

let directive =
  '#' int string newline

let whitespace =
  [' ' '\t']


(* Parsing *)
rule tokenize = parse
  | string      { STRING_CONST (Lexing.lexeme lexbuf) }
	| hex         { INT_CONST (int_of_string (Lexing.lexeme lexbuf)) }
  | int         { INT_CONST (int_of_string (filter_numeric (Lexing.lexeme lexbuf))) }
	| float       { FLOAT_CONST (float_of_string (filter_numeric (Lexing.lexeme lexbuf))) }
  | complex     { COMPLEX_CONST (float_of_string (filter_numeric (Lexing.lexeme lexbuf))) }
  | na          { NA_CONST }
  | "NULL"      { NULL_CONST }
  | symbol      { SYMBOL (Lexing.lexeme lexbuf) }
  | userop      { USEROP (let s = Lexing.lexeme lexbuf in String.sub s 1 ((String.length s) - 2)) }
  | "function"  { FUNCTION }
  | "TRUE"      { TRUE }
  | "FALSE"     { FALSE }

  | "<-"        { LEFT_ASSIGN }
  | "<<-"       { LEFT_SUPER_ASSIGN }
  | "="         { EQASSIGN }
  | "->"        { RIGHT_ASSIGN }
  | "->>"       { RIGHT_SUPER_ASSIGN }
  | ":="        { COLON_ASSIGN }

  | "for"       { FOR } 
  | "in"        { IN }
  | "if"        { IF }
  | "else"      { ELSE }
  | "while"     { WHILE }
  | "next"      { NEXT }
  | "break"     { BREAK }
  | "repeat"    { REPEAT }

  | ">"         { GT }
  | ">="        { GE }
  | "<"         { LT }
  | "<="        { LE }
  | "=="        { EQ }
  | "!="        { NE }
  | "&&"        { AND }
  | "&"         { ANDVEC }
  | "||"        { OR }
  | "|"         { ORVEC }

  | "+"         { PLUS }
  | "-"         { MINUS }
  | "*"         { MULT }
  | "/"         { DIV }
  | "%/%"       { INTDIV }
  | "%*%"       { MATRIXMULT }
  | "%o%"       { OUTERPROD }
  | "%x%"       { KRONECKERPROD }
  | "%in%"      { IN }

  | "::"        { NS_GET }
  | ":::"       { NS_GET_INT }

  | "("         { LPAREN }
  | ")"         { RPAREN }
  | "{"         { LBRACE }
  | "}"         { RBRACE }
  | "["         { LBRACK }
  | "]"         { RBRACK }

  | ":"         { COLON }
  | ";"         { SEMI }
  | "?"         { QUESTION }
  | "!"         { BANG }
  | "$"         { DOLLAR }
  | "@"         { AT }
  | "~"         { TILDE }
  | ","         { COMMA }
  
  (* INCOMPLETE_STRING *)
  (* SYMBOL_FORMALS *)
  (* EQ_FORMALS *)
  (* EQ_SUB *)
  (* SYMBOL_SUB *)
  (* SYMBOL_FUNCTION_CALL *)
  (* SYMBOL_PACKAGE *)

  | comment     { tokenize lexbuf }
  | directive   { tokenize lexbuf }
  | whitespace  { tokenize lexbuf }
  | newline     { NEWLINE }
  | eof         { END_OF_INPUT }

