
open Syntax
open Absyn_generator
open Loader
open Engine
open Interputils
open Smt

open Sys

let default_steps : int = 100

let main () =
  print_endline "SimpleR: complies!";
  (* dump_file_linearization "/home/celery/Desktop/base/R" "test.R"; *)
  (* dump_file_ast "/home/celery/foo/harvard/r-test/tutorial/Rdemo/Notes.R" *)
  (* dumpTokens "/home/celery/Desktop/base/R/aperm.R"; *)
  (* parseFile "/home/celery/Desktop/base/R/aperm.R" *)
  let state = load_file_guess Sys.argv.(1) in
  let n = if Array.length Sys.argv < 3 then
            default_steps
          else
            int_of_string Sys.argv.(2) in

  let ress = run_n_hist n [state] in
  print_endline (string_of_passresult_list ress);
  (*

  let res = run_n n [state] in
  print_endline (string_of_passresult res);
  *)

  (*
  let res = get_first_completed_after_n n [state] in
  print_endline (string_of_value_attr_opt_pair res);
  *)


  print_endline "SimpleR: done!";
  ;;
  

main ()

