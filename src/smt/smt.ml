open Smtsyntax
open Smt2
open Solver
open Smtutils

let test_smtcmd_list : unit -> smtcmd list =
  fun _ ->
    [SmtDeclFun ("x", [], SmtSortInt);
     SmtDeclFun ("y", [], SmtSortInt);
     SmtAssert (SmtEq (SmtVar "x", SmtVar "y"));
     SmtCheckSat;
     SmtGetModel;
     SmtExit;
    ]

let test_z3 : unit -> string =
  fun _ ->
    let smt2 = smt2_of_smtcmd_list (test_smtcmd_list ()) in
      run_z3 smt2

