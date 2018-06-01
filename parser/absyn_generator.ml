
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


let parseFile filename =
  let channel = open_in filename  in
  let lexbuf = Lexing.from_channel channel   in
  let absyn =
     try
       Parser.prog Lexer.tokenize lexbuf
     with _ ->
          let pos = lexbuf.Lexing.lex_curr_p in
            begin

              print_string "Syntax error detected at line ";
              print_string (string_of_int pos.Lexing.pos_lnum );
              print_string " column ";
              print_string (string_of_int (pos.Lexing.pos_cnum -
                                           pos.Lexing.pos_bol ) );
              print_string ".\n\n";
              failwith "Syntax error"
            end  in
  let _ = close_in channel  in
  absyn

let dumpTokens : string -> unit =
  fun filename ->
    let channel = open_in filename in
    let lexbuf = Lexing.from_channel channel in
      while true do
        let tok = Lexer.tokenize lexbuf in
          print_endline (string_of_token tok);
          flush stdout
      done
    

let main () =
  let args = Array.to_list Sys.argv  in
  let in_filename = match args with
                  | [_; arg] -> arg
                  | _     -> failwith "exactly one filename expected"  in
  (* Parsing *)
  let absyn = parseFile in_filename  in
    print_endline (Rast.string_of_program absyn);
    dumpTokens in_filename;
    ;;

main ()

