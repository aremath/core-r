
(*
open Language
*)
module R = Rast
module S = Syntax
module T = Support
open Absyn_generator
open Filename
open Sys

type rastexpr = unit R.expr

module StringMap = Map.Make(String)

type deptable = string StringMap.t

let empty_deptable : deptable =
  StringMap.empty

let canonicalize_R_file : string -> string -> string =
  fun dir file ->
    if is_relative file then
      dirname dir ^ "/" ^ file
    else
      file

let rasts_of_file : string -> rastexpr list =
  fun file ->
    parseFile file

let source_call_of_rast : rastexpr -> string list =
  fun expr -> match expr with
    | R.FuncCall (R.Ident id, [R.ExprArg (R.StringConst src)]) ->
        if id.R.name = "source" then
          [src]
        else
          []
    | _ -> []

let file_dependencies : string -> string -> string list =
  fun dir file ->
    let rasts = rasts_of_file (canonicalize_R_file dir file) in
      List.concat (List.map source_call_of_rast rasts)

let dependency_graph : string -> string -> deptable -> string =
  fun a _ _ -> a

let merge_heap : T.heap -> T.heap -> T.heap =
  fun heap1 heap2 -> heap2

let merge_env : T.env -> T.env -> T.env =
  fun env1 env2 -> env2

let load_file : string -> string -> (T.env * T.heap) option =
  fun dir file -> None

