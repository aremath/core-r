(*
  Adapted from:
    https://github.com/wch/r-source/blob/trunk/src/main/gram.y 
*)

{}

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

let numeric =
    hex
  | float
  | complex
  | "NA"
  | "TRUE"
  | "FALSE"
  | "Inf"
  | "NaN"
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
let user_op =
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
  | eof         { END_OF_INPUT }

  | string      { STR_CONST (Lexing.lexeme lexbuf) }
  | numeric     { NUM_CONST (Lexing.lexeme lexbuf) }
  | "NULL"      { NULL_CONST }
  | symbol      { SYMBOL (Lexing.lexeme lexbuf) }
  | "function"  { FUNCTION }

  (* INCOMPLETE_STRING *)

  | "<-"        { LEFT_ASSIGN }
  | "="         { EQASSIGN }
  | "->"        { RIGHTASSIGN }
  | "[["        { LBB }

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

  | "::"        { NS_GET }
  | ":::"       { NS_GET_INT }

  | comment     { COMMENT (Lexing.lexeme lexbuf) }
  | directive   { LINE_DIRECTIVE (Lexing.lexeme lexbuf) }

  (* SYMBOL_FORMALS *)
  (* EQ_FORMALS *)
  (* EQ_SUB *)
  (* SYMBOL_SUB *)
  (* SYMBOL_FUNCTION_CALL *)
  (* SYMBOL_PACKAGE *)
  
  | ":="        { COLON_ASSIGN }
  | "@"         { SLOT }


