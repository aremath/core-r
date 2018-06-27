
open Syntax
open Absyn_generator
open Loader
open Interputils
open Sys

let main () =
  print_endline "complies!";
  (* dump_file_linearization "/home/celery/Desktop/base/R" "test.R"; *)
  (* dump_file_ast "/home/celery/foo/harvard/r-test/tutorial/Rdemo/Notes.R" *)
  (* dumpTokens "/home/celery/Desktop/base/R/aperm.R"; *)
  (* parseFile "/home/celery/Desktop/base/R/aperm.R" *)
  let state = load_file_guess Sys.argv.(1) in
  print_endline (string_of_state state);
  print_endline "done!";
  ;;
  

main ()

