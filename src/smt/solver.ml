
open Smt2

open Filename
open Sys

let z3_eof : unit -> string =
  fun _ -> "Z3_END_OF_INPUT"

let z3_cmd_of_smt2 : smt2 -> string =
  fun smt2 ->
    "z3 -smt2 -in <<" ^
    z3_eof () ^ "\n" ^
    string_of_smt2 smt2 ^ "\n" ^
    z3_eof ()

let run_z3 : smt2 -> string =
  fun smt2 ->
    let cmd = z3_cmd_of_smt2 smt2 in
    let tmp_file = temp_file "" ".txt" in
    let _ = command (cmd ^ " > " ^ tmp_file) in
    let str = ref "" in
    let tmp_in = open_in tmp_file in
    try
      while true do
        let line = input_line tmp_in in
        str := !str ^ "\n" ^ line
      done;
      !str
    with e ->
      let _ = close_in tmp_in in
        !str

