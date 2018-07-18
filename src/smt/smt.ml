open Smtsyntax
open Support
open Smt2
open Solver

let test_smtstmts : unit -> smtstmt list =
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
    let smt2 = smt2_of_smtstmts (test_smtstmts ()) in
      run_z3 smt2

