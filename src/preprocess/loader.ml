
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

module StringSet = Set.Make(String)

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
    let deps = List.concat (List.map source_call_of_rast rasts) in
      List.map (canonicalize_R_file dir) deps

let rec dependency_graph_list :
  string -> string -> StringSet.t -> string list * StringSet.t =
  fun dir file set ->
    let canon_name = canonicalize_R_file dir file in
    if StringSet.mem canon_name set then
      failwith ("circular dependency: already seen: " ^ canon_name)
    else
      let set2 = StringSet.add canon_name set in
      let file_deps = file_dependencies dir file in
        List.fold_left (fun (acc, s) c ->
                          let (c_acc, c_s) = dependency_graph_list dir c s in
                            (acc @ c_acc, c_s))
                       ([canon_name], set2) file_deps

(*
let env_of_rast : rastexpr list -> T.env =
  fun 
*)


let merge_heap : T.heap -> T.heap -> T.heap =
  fun heap1 heap2 -> heap2

let merge_env : T.env -> T.env -> T.env =
  fun env1 env2 -> env2

let load_file : string -> string -> (T.env * T.heap) option =
  fun dir file -> None

