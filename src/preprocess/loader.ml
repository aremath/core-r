
(*
open Language
*)
module R = Rast
module S = Syntax
module T = Support
open List
open Langutils
open Rast_to_language
open Absyn_generator
module F = Filename
open Sys

type memref = S.memref
type env = T.env
type heapobj = T.heapobj
type heap = T.heap
type expr = T.expr
type ident = T.ident
type rastexpr = unit R.expr

module StringSet = Set.Make(String)

let canonicalize_R_file : string -> string -> string =
  fun dir file ->
    if F.is_relative file then
      F.dirname dir ^ "/" ^ file
    else
      file

let exprs_of_file : string -> expr list =
  fun file ->
    map convert_expr (parseFile file)

let source_call_of_expr : expr -> string list =
  fun expr ->
    match expr with
    | S.LambdaApp (S.Ident id, [S.Arg (S.Const (S.Str (Some src)))]) ->
      (match id.S.name with
      | Some ("source") -> [src]
      | _ -> [])
    | _ -> []

let assigns_of_expr : expr -> (ident * expr) list =
  fun expr ->
    match expr with
    | S.Assign (S.Ident id, rhs) -> [(id, rhs)]
    | S.Assign (S.Const (S.Str rstr), rhs) -> [(T.id_of_rstring rstr, rhs)]
    | _ -> []

let file_dependencies : string -> string -> string list =
  fun dir file ->
    let exprs = exprs_of_file (canonicalize_R_file dir file) in
    let deps = concat (map source_call_of_expr exprs) in
      map (fun f -> canonicalize_R_file dir f) deps

let rec dependency_graph_list :
  string -> string -> StringSet.t -> string list * StringSet.t =
  fun dir file set ->
    let canon_name = canonicalize_R_file dir file in
    if StringSet.mem canon_name set then
      failwith ("dependency_graph_list: circular dependency: already seen: " ^
                canon_name)
    else
      let set2 = StringSet.add canon_name set in
      let file_deps = file_dependencies dir file in
        fold_left (fun (acc, s) c ->
                          let (c_acc, c_s) = dependency_graph_list dir c s in
                            (acc @ c_acc, c_s))
                       ([canon_name], set2) file_deps

let inj_binds_to_heap_global : (ident * expr) list -> memref -> heap -> heap =
  fun binds env_mem heap ->
    match T.heap_find env_mem heap with
    | Some (T.DataObj (T.EnvVal env, attrs)) ->
        let ids = map (fun (i, _) -> i) binds in
        let proms = map (fun (_, e) -> T.PromiseObj (e, env_mem)) binds in
        let (mems, heap2) = T.heap_alloc_list proms heap in
        let env_binds = combine ids mems in
        let env2 = T.env_add_list env_binds env in
          T.heap_add env_mem (T.DataObj (T.EnvVal env2, attrs)) heap2
    | _ -> failwith ("inj_binds_to_heap_global: did not find env at " ^
                     string_of_memref env_mem)

let rec inj_heap_list : (memref * heapobj) list -> heap -> heap =
  fun binds heap ->
    match binds with
    | [] -> heap
    | ((mem, hobj) :: binds_tl) ->
        match T.heap_find mem heap with
        | None -> inj_heap_list binds_tl (T.heap_add mem hobj heap)
        | Some _ -> failwith ("inj_heap_list: binding exists at: " ^
                               string_of_memref mem)

(* Inject heap1 into heap2 *)
let merge_heap : heap -> heap -> heap =
  fun heap1 heap2 ->
    inj_heap_list (T.binds_of_heap heap1) heap2


let load_file : string -> string -> env * heap =
  fun dir file -> (T.env_empty, T.heap_empty)

