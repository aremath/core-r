
{ }

let hex =
  ['0'-'9' 'a'-'f' 'A'-'F']

let hex_int =
  '0' ['x' 'X'] hex+

let digit =
  ['0'-'9']

let dec_int =
  digit+

let exp =
  ['e' 'E'] ['+' '-']? dec_int

let float =
    digit+ '.' digit* exp?
  | digit+ exp?
  | '.' digit+ exp?

let complex =
    dec_int 'i'
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

let id =
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
  | '('       { LPAREN }
  | ')'       { RPAREN }

  | '['       { LBRACKET }
  | ']'       { RBRACKET }

  | '{'       { LBRACE }
  | '}'       { RBRACE }

  (* Operators (cf 3.1.4) *)
  | '-'       { MINUS }
  | '+'       { PLUS }
  | '!'       { UNOT }
  | '~'       { TILDE } 
  | '?'       { HELP } 
  | ':'       { SEQUENCE }
  | '*'       { MULT }
  | '/'       { DIV }
  | '^'       { EXP }
  | "%%"      { MODULUS }
  | "%/%"     { INTDIVISION }
  | "%*%"     { MATRIXMULT }
  | "%o%"     { OUTERPROD }
  | "%x%"     { KRONECKERPROD }
  | '<'       { LT }
  | '>'       { GT }
  | "=="      { EQ }
  | ">="      { GE }
  | "<="      { LE }
  | '&'       { ANDVEC }
  | "&&"      { ANDNOVEC }
  | '|'       { ORVEC }
  | "||"      { ORNOVEC }
  | "<-"      { LASSIGN }
  | "->"      { RASSIGN }
  | '$'       { LISTSUBSET }

  (* Additional operators (cf 10.4.2) *)
  | "::"      { NAMESPACE }
  | '@'       { ATTRIBUTE }
  | "<<-"     { LSUPASSIGN }
  | "->>"     { RSUPASSIGN }
  | '='       { ASSIGN }

  (* Keywords *)


  (* End of file *)
  | eof       { EOF }



