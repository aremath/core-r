
open Syntax
open Absyn_generator
open Loader
open Engine
open Interputils

open Sys

let default_steps : int = 100

let main () =
  print_endline "complies!";
  (* dump_file_linearization "/home/celery/Desktop/base/R" "test.R"; *)
  (* dump_file_ast "/home/celery/foo/harvard/r-test/tutorial/Rdemo/Notes.R" *)
  (* dumpTokens "/home/celery/Desktop/base/R/aperm.R"; *)
  (* parseFile "/home/celery/Desktop/base/R/aperm.R" *)
  let state = load_file_guess Sys.argv.(1) in
  let n = if Array.length Sys.argv < 2 then
            default_steps
          else
            int_of_string Sys.argv.(2) in
  let init = [([], state)] in

  let ress = run_n_hist n [([], [], init)] init in
  (*
    print_endline (string_of_passresult_list ress);
  *)
  print_endline (string_of_passresult_list_first_complete ress);

  print_endline "done!";
  ;;
  

main ()

