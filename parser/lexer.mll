(*
  Adapted from: https://github.com/antlr/grammars-v4/blob/master/r/R.g4
*)

{
  open Parser

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

    let nl_ignore : Parser.token -> bool =
        function
            | WHILE             -> true
            | USER_OP _         -> true
            | TRUE              -> false (* a value *)
            | TILDE             -> true
            | SYMBOL _          -> false (* a value *)
            | STRING_CONST _    -> false (* a value *)
            | SEMI              -> false (* TODO ? *)
            | RSUPER_ASSIGN     -> true
            | RPAREN            -> true
            | REPEAT            -> true
            | RBRACK            -> true
            | RBRAX             -> true
            | RBRACE            -> false (* braces is a block of newline-separated exprs*)
            | RASSIGN           -> true
            | QUESTION          -> true
            | PLUS              -> true
            | OUTER_PROD        -> true
            | OR2               -> true
            | OR                -> true
            | NULL              -> false (* a value *)
            | NS_GET_INT        -> false (* not sure why *)
            | NS_GET            -> false (* ^ *)
            | NEXT              -> false (* nothing expected after next *)
            | NEWLINE           -> false (* TODO *)
            | NE                -> true
            | NAN               -> false (* a value *)
            | NA                -> false (* a value *)
            | MULT              -> true
            | MOD               -> true
            | MINUS             -> true
            | MATRIX_MULT       -> true
            | MATCH             -> true
            | LT                -> true
            | LSUPER_ASSIGN     -> true
            | LPAREN            -> true
            | LE                -> true
            | LBRACK            -> true
            | LBRAX             -> true
            | LBRACE            -> false (* nothing expected after lbrace *)
            | LASSIGN           -> true
            | KRON_PROD         -> true
            | INT_DIV           -> true
            | INT_CONST _       -> false (* a value *)
            | INFINITY          -> false (* a value *)
            | IN                -> true  (* for expects expr after in *)
            | IF                -> true  (* expect (cond) *)
            | GT                -> true
            | GE                -> true
            | FUNCTION          -> true (* expect (args) *)
            | FOR               -> true (* expect (var in expr) expr *)
            | FLOAT_CONST _     -> false (* a value *)
            | FALSE             -> false (* a value *)
            | EQ_ASSIGN         -> true
            | EQ                -> true
            | END_OF_INPUT      -> false
            | ELSE              -> true (* expect expr *)
            | DOLLAR            -> true
            | DIV               -> true
            | COMPLEX_CONST _   -> false (* a value *)
            | COMMA             -> false (* doesn't matter *)
            | COLON             -> true
            | CARAT             -> true
            | BREAK             -> false
            | BANG              -> true
            | AT                -> true (* TODO ? *)
            | AND2              -> true
            | AND               -> true

    (* What tokens affect the context - many tokens do not affect the context and are
    pushed zero times. Binops affect the context once. Something like an if (where both the
    condition and the expression can be placed with newlines) will be pushed twice *)
    to_push: Parser.token -> Parser.token list =
        function
            | WHILE             -> [WHILE; WHILE] (* expect (cond) expr *)
            | TRUE              -> [TRUE]
            | SYMBOL _          -> []
            | STRING_CONST _    -> []
            | SEMI              -> []
            | RPAREN            -> [] (* ends LPAREN, not pushed *)
            | REPEAT            -> [REPEAT] (* expect expr *)
            | RBRACK            -> [] (* ends LBRACK *)
            | RBRAX             -> [] (* ends LBRAX, not pushed *)
            | RBRACE            -> [] (* ends LBRACE, but not pushed *)
            | NULL              -> []
            | NS_GET_INT        -> []
            | NS_GET            -> []
            | NEXT              -> []
            | NEWLINE           -> []
            | NAN               -> []
            | NA                -> []
            | LPAREN            -> [LPAREN] (* expect expr *)
            | LBRACE            -> [LBRACE] (* don't expect *)
            | INT_CONST _       -> []
            | INFINITY          -> []
            | IN                -> [] (* expect expr, but it doesn't matter *)
            | IF                -> [IF; IF] (* expect (cond) body (else body2?) *)
            | FUNCTION          -> [FUNCTION; FUNCTION] (* expect (args) expr *)
            | FOR               -> [FOR; FOR] (* expect (var in expr) expr *)
            | FLOAT_CONST _     -> []
            | FALSE             -> []
            | END_OF_INPUT      -> []
            | ELSE              -> [ELSE] (* expect expr *)
            | COMPLEX_CONST _   -> []
            | COMMA             -> []
            | BREAK             -> []
            | x                 -> [x] (* Binops *)

    (* which tokens match which other tokens *)
    token_match: Parser.token -> Parser.token -> true = 
        fun t1 t2 ->
            match t1 with
            begin
            | WHILE             -> true (* things that expect expr, which can begin with any token *)
            | USER_OP _         -> true
            | TILDE             -> true
            | RSUPER_ASSIGN     -> true
            | RPAREN            -> match t2 with
                                    | LPAREN    -> true
                                    | _         -> false
            | REPEAT            -> true
            | RBRACK            -> match t2 with
                                    | LBRACK    -> true
                                    | _         -> false
            | RBRAX             -> match t2 with
                                    | LBRAX     -> true
                                    | _         -> false
            | RBRACE            -> match t2 with
                                    | LBRACE    -> true
                                    | _         -> false
            | RASSIGN           -> true
            | QUESTION          -> true
            | PLUS              -> true
            | OUTER_PROD        -> true
            | OR2               -> true
            | OR                -> true
            | NE                -> true
            | MULT              -> true
            | MOD               -> true
            | MINUS             -> true
            | MATRIX_MULT       -> true
            | MATCH             -> true
            | LT                -> true
            | LSUPER_ASSIGN     -> true
            | LPAREN            -> match t2 with
                                    | RPAREN    -> true
                                    | _         -> false
            | LE                -> true
            | LBRACK            -> match t2 with
                                    | RBRACK    -> true
                                    | _         -> false
            | LBRAX             -> match t2 with
                                    | RBRAX     -> true
                                    | _         -> false
            | LBRACE            -> match t2 with
                                    | RBRACE    -> true
                                    | _         -> false
            | LASSIGN           -> true
            | KRON_PROD         -> true
            | INT_DIV           -> true
            | IF                -> true  (*  *)
            | GT                -> true
            | GE                -> true
            | FUNCTION          -> true (* expect (args) *)
            | FOR               -> true (* expect (var in expr) expr *)
            | EQ_ASSIGN         -> true
            | EQ                -> true
            | ELSE              -> true (* expect expr *)
            | DOLLAR            -> true
            | DIV               -> true
            | COLON             -> true
            | CARAT             -> true
            | BANG              -> true
            | AT                -> true (* TODO ? *)
            | AND2              -> true
            | AND               -> true
            | _                 -> false
            end

(* The general algorithm for this is when we see a token, if it affects the context,
put it on the stack, then use its behavior until a match is found, at which point it is
removed from the stack, and we go back to the newline behavior of the character under it.
Tokens that do not have a match do not go onto the context stack.*)
    step token : Parser.token -> Parser.token list ref -> bool ref -> () =
        fun tok context_ref ->
            let top = match !context_ref with
            | hd::tl        -> hd
            | []            -> LBRACE (* TODO *)
            in
            (* if the top token of the context matches the current token, pop the top*)
            let _ = if token_match top tok then
                (!context_ref := List.tl !context_ref);
                else () in
            (* push tok onto the stack *)
            let x = to_push tok in
            (!context_ref := x :: !context_ref);
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

(* Missing the %in% matring operator *)
let user_op =
  '%' [^ '/' '*' 'o' 'x']+ '%'

let newline =
    '\n'
  | '\r'
  | '\r' '\n'

let comment =
  '#' ([^ '\n']*)

let whitespace =
  [' ' '\t']


(* Parsing *)
rule tokenize = parse
  (* Delimiters *)
  | "("         { LPAREN }
  | ")"         { RPAREN }

  | "["         { LBRACK }
  | "]"         { RBRACK }

  | "[["        { LBRAX }
  | "]]"        { RBRAX }

  | "{"         { LBRACE }
  | "}"         { RBRACE }

  (* Operators (cf 3.1.4) *)
  | "-"         { MINUS }
  | "+"         { PLUS }
  | "!"         { BANG }
  | "~"         { TILDE }
  | "?"         { QUESTION }
  | ":"         { COLON }
  | "*"         { MULT }
  | "/"         { DIV }
  | "^"         { CARAT }
  | "%%"        { MOD }
  | "%/%"       { INT_DIV }
  | "%*%"       { MATRIX_MULT }
  | "%o%"       { OUTER_PROD }
  | "%x%"       { KRON_PROD }
  | "%in%"      { MATCH }
  | "<"         { LT }
  | ">"         { GT }
  | "=="        { EQ }
  | "!="        { NE }
  | ">="        { GE }
  | "<="        { LE }
  | "&&"        { AND }
  | "&"         { AND2 }
  | "||"        { OR }
  | "|"         { OR2 }
  | "<-"        { LASSIGN }
  | "->"        { RASSIGN }
  | "$"         { DOLLAR }

  (* Additional operators (cf 10.4.2) *)
  | "::"        { NS_GET }
  | ":::"       { NS_GET_INT }
  | "@"         { AT }
  | "<<-"       { LSUPER_ASSIGN }
  | "->>"       { RSUPER_ASSIGN }
  | "="         { EQ_ASSIGN }

  (* Were not listed but likely relevant *)
  | ";"         { SEMI }
  | ":="        { EQ_ASSIGN }
  | "..."       { SYMBOL (Lexing.lexeme lexbuf) }

  (* Keywords *)
  | "function"  { FUNCTION }
  | "if"        { IF }
  | "else"      { ELSE }
  | "for"       { FOR }
  | "in"        { IN }
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
  | ident       { SYMBOL (Lexing.lexeme lexbuf) }
  | user_op     { USER_OP (Lexing.lexeme lexbuf) }
  | string      { STRING_CONST (Lexing.lexeme lexbuf) }
  | hex         { INT_CONST (int_of_string (Lexing.lexeme lexbuf)) }
  | int         { INT_CONST (int_of_string (filter_numeric (Lexing.lexeme lexbuf))) }
  | float       { FLOAT_CONST (float_of_string (Lexing.lexeme lexbuf)) }
  | complex     { COMPLEX_CONST (float_of_string (filter_numeric (Lexing.lexeme lexbuf))) }

  (* To be skipped, maybe *)
  | comment     { tokenize lexbuf; NEWLINE }
  | whitespace  { tokenize lexbuf }

  | newline     { incr_line_count lexbuf; NEWLINE }
  | ','         { COMMA }

  (* Everybody's favorite thing that's technically not a char some times *)
  | eof         { END_OF_INPUT }


