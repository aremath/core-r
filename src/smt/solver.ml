
open Smtsyntax
open Smt2

open Filename
open Sys

let z3_eof : unit -> string =
  fun _ -> "Z3_END_OF_INPUT"

let tmp_file : unit -> string =
  fun _ -> getcwd () ^ "/~z3-tmp.swp"

let z3_cmd_of_smt2 : smt2 -> string =
  fun smt2 ->
    "z3 -smt2 -in <<" ^
    z3_eof () ^ "\n" ^
    string_of_smt2 smt2 ^ "\n" ^
    z3_eof () ^ "\n"

let run_z3 : smt2 -> smtprog =
  fun smt2 ->
    let cmd = (z3_cmd_of_smt2 smt2) ^ " > " ^ tmp_file () in
    let _ = command cmd in
    let tmp_in = open_in (tmp_file ()) in
    let lexbuf = Lexing.from_channel tmp_in in
    let prog =
      try
        Smtparser.prog (Smtlexer.tokenize (ref [])) lexbuf
      with _ ->
        let pos = lexbuf.Lexing.lex_curr_p in
        begin
          print_string "Syntax error detected at line ";
          print_string (string_of_int pos.Lexing.pos_lnum);
          print_string " column ";
          print_string (string_of_int (pos.Lexing.pos_cnum -
                                       pos.Lexing.pos_bol));
          print_endline ".";
          failwith "Syntax error"
        end
        in
      let _ = close_in tmp_in in
        prog


