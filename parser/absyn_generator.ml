
    
let parseFile filename =
  let channel = open_in filename  in
  let lexbuf = Lexing.from_channel channel   in
  let absyn =
     try
       Parser.program Lexer.tokenize lexbuf
     with _ ->
          let pos = lexbuf.Lexing.lex_curr_p in
            begin

              print_string "Syntax error detected at line ";
              print_string ( string_of_int pos.Lexing.pos_lnum );
              print_string " column ";
              print_string ( string_of_int (pos.Lexing.pos_cnum -
                                              pos.Lexing.pos_bol ) );
              print_string ".\n\n";
              failwith "Syntax error"
            end  in
  let _ = close_in channel  in
  absyn

let main () =
  print_string "invoked main\n";
  let args = Array.to_list Sys.argv  in
  let in_filename = match args with
                  | [_; arg] -> arg
                  | _     -> failwith "exactly one filename expected"  in
  (* Parsing *)
  let absyn = parseFile in_filename  in
  print_endline (Absyn.string_of_program absyn)

main()
