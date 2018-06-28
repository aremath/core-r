
open Syntax
open Absyn_generator
open Loader
open Engine
open Interputils
open Sys

let main () =
  print_endline "complies!";
  (* dump_file_linearization "/home/celery/Desktop/base/R" "test.R"; *)
  (* dump_file_ast "/home/celery/foo/harvard/r-test/tutorial/Rdemo/Notes.R" *)
  (* dumpTokens "/home/celery/Desktop/base/R/aperm.R"; *)
  (* parseFile "/home/celery/Desktop/base/R/aperm.R" *)
  let state = load_file_guess Sys.argv.(1) in
  let n = int_of_string Sys.argv.(2) in
  let init = [([], state)] in
  let ress = run_n_hist n [([], [], init)] init in
  print_endline (string_of_passresult_list ress);
  print_endline "done!";
  ;;
  

main ()

