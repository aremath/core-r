module M = Absyn_generator

let main () =
  let args = Array.to_list Sys.argv  in
  let in_filename = match args with
                  | [_; arg] -> arg
                  | _     -> failwith "exactly one filename expected"  in
  (* Parsing *)
  (* let _ = dumpTokens in_filename in *)
  let absyn = List.map (Rast_to_language.convert_expr) (M.parseFile in_filename) in
    (* print_endline (Rast.string_of_program absyn); *)
    ();;

main ()

