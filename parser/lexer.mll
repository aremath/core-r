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

    let string_of_token : Parser.token -> string =
      function
        | END_OF_INPUT -> raise (Failure "END_OF_INPUT")
        | WHILE -> "WHILE"
        | USER_OP s -> "USER_OP (" ^ s ^ ")"
        | TRUE -> "TRUE"
        | TILDE -> "TILDE"
        | SYMBOL s -> "SYMBOL (" ^ s ^ ")"
        | STRING_CONST s -> "STRING_CONST (" ^ s ^ ")"
        | SEMI -> "SEMI"
        | RSUPER_ASSIGN -> "RSUPER_ASSIGN"
        | RPAREN -> "RPAREN"
        | REPEAT -> "REPEAT"
        | RBRACK -> "RBRACK"
        | RBRAX  -> "RBRAX"
        | RBRACE -> "RBRACE"
        | RASSIGN -> "RASSIGN"
        | QUESTION -> "QUESTION"
        | PLUS -> "PLUS"
        | OUTER_PROD -> "OUTER_PROD"
        | OR2 -> "OR2"
        | OR -> "OR"
        | NULL -> "NULL"
        | NS_GET_INT -> "NS_GET_INT"
        | NS_GET -> "NS_GET"
        | NEXT -> "NEXT"
        | NEWLINE -> "NEWLINE"
        | NE -> "NE"
        | NAN -> "NAN"
        | NA -> "NA"
        | MULT -> "MULT"
        | MOD -> "MOD"
        | MINUS -> "MINUS"
        | MATRIX_MULT -> "MATRIX_MULT"
        | MATCH -> "MATCH"
        | LT -> "LT"
        | LSUPER_ASSIGN -> "LSUPER_ASSIGN"
        | LPAREN -> "LPAREN"
        | LE -> "LE"
        | LBRACK -> "LBRACK"
        | LBRAX  -> "LBRAX"
        | LBRACE -> "LBRACE"
        | LASSIGN -> "LASSIGN"
        | KRON_PROD -> "KRON_PROD"
        | INT_DIV -> "INT_DIV"
        | INT_CONST i -> "INT_CONST (" ^ (string_of_int i) ^ ")"
        | INFINITY -> "INFINITY"
        | IN -> "IN"
        | IF -> "IF"
        | GT -> "GT"
        | GE -> "GE"
        | FUNCTION -> "FUNCTION"
        | FOR -> "FOR"
        | FLOAT_CONST f -> "FLOAT_CONST (" ^ (string_of_float f) ^ ")"
        | FALSE -> "FALSE"
        | EQ_ASSIGN -> "EQ_ASSIGN"
        | EQ -> "EQ"
        | ELSE -> "ELSE"
        | DOLLAR -> "DOLLAR"
        | DIV -> "DIV"
        | COMPLEX_CONST f -> "COMPLEX_CONST (" ^ (string_of_float f) ^ ")"
        | COMMA -> "COMMA"
        | COLON -> "COLON"
        | CARAT -> "CARAT"
        | BREAK -> "BREAK"
        | BANG -> "BANG"
        | AT -> "AT"
        | AND2 -> "AND2"
        | AND -> "AND"

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
    let to_push: Parser.token -> Parser.token list =
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
    let token_match: Parser.token -> Parser.token -> bool = 
        fun t1 t2 ->
        begin
            match t1 with
            | WHILE             -> true (* things that expect expr, which can begin with any token *)
            | USER_OP _         -> true
            | TILDE             -> true
            | RSUPER_ASSIGN     -> true
            | RPAREN            -> (match t2 with
                                    | LPAREN    -> true
                                    | _         -> false)
            | REPEAT            -> true
            | RBRACK            -> (match t2 with
                                    | LBRACK    -> true
                                    | _         -> false)
            | RBRAX             -> (match t2 with
                                    | LBRAX     -> true
                                    | _         -> false)
            | RBRACE            -> (match t2 with
                                    | LBRACE    -> true
                                    | _         -> false)
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
            | LPAREN            -> (match t2 with
                                    | RPAREN    -> true
                                    | _         -> false)
            | LE                -> true
            | LBRACK            -> (match t2 with
                                    | RBRACK    -> true
                                    | _         -> false)
            | LBRAX             -> (match t2 with
                                    | RBRAX     -> true
                                    | _         -> false)
            | LBRACE            -> (match t2 with
                                    | RBRACE    -> true
                                    | _         -> false)
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

let get_top : Parser.token list ref -> Parser.token =
    fun context_ref ->
        match !context_ref with
        | hd::tl -> hd
        | []     -> LBRACE (* TODO *)

(* The general algorithm for this is when we see a token, if it affects the context,
put it on the stack, then use its behavior until a match is found, at which point it is
removed from the stack, and we go back to the newline behavior of the character under it.
Tokens that do not have a match do not go onto the context stack.*)
    let step : Parser.token -> (Parser.token list) ref -> unit =
        fun tok context_ref ->
            let top = get_top context_ref in
            (* if the top token of the context matches the current token, pop the top*)
            let _ = if (token_match top tok) then
                context_ref := (List.tl !context_ref)
                else () in
            (* push tok onto the stack *)
            let x = to_push tok in
            context_ref := x @ !context_ref

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
rule tokenize context = parse
  (* Delimiters *)
  | "("         { step LPAREN context; LPAREN }
  | ")"         { step RPAREN context; RPAREN }

  | "["         { step LBRACK context; LBRACK }
  | "]"         { step RBRACK context; RBRACK }

  | "[["        { step LBRAX context; LBRAX }
  | "]]"        { step RBRAX context; RBRAX }

  | "{"         { step LBRACE context; LBRACE }
  | "}"         { step RBRACE context; RBRACE }

  (* Operators (cf 3.1.4) *)
  | "-"         { step MINUS context; MINUS }
  | "+"         { step PLUS context; PLUS }
  | "!"         { step BANG context; BANG }
  | "~"         { step TILDE context; TILDE }
  | "?"         { step QUESTION context; QUESTION }
  | ":"         { step COLON context; COLON }
  | "*"         { step MULT context; MULT }
  | "/"         { step DIV context; DIV }
  | "^"         { step CARAT context; CARAT }
  | "%%"        { step MOD context; MOD }
  | "%/%"       { step INT_DIV context; INT_DIV }
  | "%*%"       { step MATRIX_MULT context; MATRIX_MULT }
  | "%o%"       { step OUTER_PROD context; OUTER_PROD }
  | "%x%"       { step KRON_PROD context; KRON_PROD }
  | "%in%"      { step MATCH context; MATCH }
  | "<"         { step LT context; LT }
  | ">"         { step GT context; GT }
  | "=="        { step EQ context; EQ }
  | "!="        { step NE context; NE }
  | ">="        { step GE context; GE }
  | "<="        { step LE context; LE }
  | "&&"        { step AND context; AND }
  | "&"         { step AND2 context; AND2 }
  | "||"        { step OR context; OR }
  | "|"         { step OR2 context; OR2 }
  | "<-"        { step LASSIGN context; LASSIGN }
  | "->"        { step RASSIGN context; RASSIGN }
  | "$"         { step DOLLAR context; DOLLAR }

  (* Additional operators (cf 10.4.2) *)
  | "::"        { step NS_GET context; NS_GET }
  | ":::"       { step NS_GET_INT context; NS_GET_INT }
  | "@"         { step AT context; AT }
  | "<<-"       { step LSUPER_ASSIGN context; LSUPER_ASSIGN }
  | "->>"       { step RSUPER_ASSIGN context; RSUPER_ASSIGN }
  | "="         { step EQ_ASSIGN context; EQ_ASSIGN }

  (* Were not listed but likely relevant *)
  | ";"         { step SEMI context; SEMI }
  | ":="        { step EQ_ASSIGN context; EQ_ASSIGN }
  | "..."       { step (SYMBOL "") context; SYMBOL (Lexing.lexeme lexbuf) }

  (* Keywords *)
  | "function"  { step FUNCTION context; FUNCTION }
  | "if"        { step IF context; IF }
  | "else"      { step ELSE context; ELSE }
  | "for"       { step FOR context; FOR }
  | "in"        { step IN context; IN }
  | "while"     { step WHILE context; WHILE }
  | "repeat"    { step REPEAT context; REPEAT }
  | "next"      { step NEXT context; NEXT }
  | "break"     { step BREAK context; BREAK }

  (* Native values *)
  | "NULL"      { step NULL context; NULL }
  | "NA"        { step NA context; NA }
  | "Inf"       { step INFINITY context; INFINITY }
  | "NaN"       { step NAN context; NAN }
  | "TRUE"      { step TRUE context; TRUE }
  | "FALSE"     { step FALSE context; FALSE }

  (* Valued tokens *)
  | ident       { step (SYMBOL "") context;
                    SYMBOL (Lexing.lexeme lexbuf) }
  | user_op     { step (USER_OP "") context;
                    USER_OP (Lexing.lexeme lexbuf) }
  | string      { step (STRING_CONST "") context;
                    STRING_CONST (Lexing.lexeme lexbuf) }
  | hex         { step (INT_CONST 0) context;
                    INT_CONST (int_of_string (Lexing.lexeme lexbuf)) }
  | int         { step (INT_CONST 0) context;
                    INT_CONST (int_of_string (filter_numeric (Lexing.lexeme lexbuf))) }
  | float       { step (FLOAT_CONST 0.) context;
                    FLOAT_CONST (float_of_string (Lexing.lexeme lexbuf)) }
  | complex     { step (COMPLEX_CONST 0.) context;
                    COMPLEX_CONST (float_of_string (filter_numeric (Lexing.lexeme lexbuf))) }

  (* To be skipped, maybe *)
  | comment     { tokenize context lexbuf }
  | whitespace  { tokenize context lexbuf }

  | newline     { incr_line_count lexbuf; if nl_ignore (get_top context) then 
                                            tokenize context lexbuf else NEWLINE }
  | ','         { step COMMA context; COMMA }

  (* Everybody's favorite thing that's technically not a char some times *)
  | eof         { step END_OF_INPUT context; END_OF_INPUT }


