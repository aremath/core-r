
open Syntax
open Loader

let main () =
  print_endline "complies!";
  dump_file_linearization "/home/celery/foo/harvard/r-test/tutorial/Rdemo" "Notes.R"
  ;;
  

main ()
