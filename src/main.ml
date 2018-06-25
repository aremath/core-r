
open Syntax
open Absyn_generator
open Loader

let main () =
  print_endline "complies!";
  (* dump_file_linearization "/home/celery/Desktop/base/R" "test.R"; *)
  (* dump_file_ast "/home/celery/foo/harvard/r-test/tutorial/Rdemo/Notes.R" *)
  (* dumpTokens "/home/celery/Desktop/base/R/aperm.R"; *)
  parseFile "/home/celery/Desktop/base/R/aperm.R"
  ;;
  

main ()
