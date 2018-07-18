open Smtsyntax
open Smt2
open Solver

let test_smtstmt_list : unit -> smtstmt list =
  fun _ ->
    [SmtDeclVar ("x", SmtSortInt);
     SmtDeclVar ("y", SmtSortInt);
     SmtAssert (SmtEq (SmtVar "x", SmtVar "y"));
     SmtCheckSat;
     SmtGetModel;
     SmtExit;
    ]

let test_z3 : unit -> string =
  fun _ ->
    let smt2 = smt2_of_smtstmt_list (test_smtstmt_list ()) in
      run_z3 smt2

