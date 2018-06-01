


let string_of_token : Parser.token -> string =
  function
    | END_OF_INPUT -> raise (Failure "/*** EOF HIT ***/")
    | STRING_CONST s -> "STRING_CONST (" ^ s ^ ")"
    | SYMBOL s -> "SYMBOL (" ^ s ^ ")"
    | USER_OP s -> "USER_OP (^" ^ s ^ ")"
    | FUNCTION -> "FUNCTION"
    | _ -> "/*** UNDERSCORE ***/"

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
    dumpTokens in_filename;;
  (*
    (* Parsing *)
    let absyn = parseFile in_filename  in
    print_endline (Rast.string_of_program absyn);;
  *)

main ()

