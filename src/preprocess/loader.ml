
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

type ('a, 'b) either =
    OptA of 'a
  | OptB of 'b

type exectree =
  | ExprLeaf of string * expr
  | ExprNode of string * exectree list

let canon_of_R_file : string -> string -> string =
  fun dir file ->
    if F.is_relative file then
      dir ^ "/" ^ file
    else
      file

let exprs_of_file : string -> expr list =
  fun file ->
    map convert_expr (parseFile file)

let cat_of_expr : expr -> (string, expr) either =
  fun expr ->
    match expr with
    | S.LambdaApp (S.Ident ({ S.name = Some "source" }),
                  [S.Arg (S.Const (S.Str (Some src)))]) -> OptA src
    | _ -> OptB expr

let cats_of_file : string -> string * ((string, expr) either) list =
  fun file ->
    (file, map cat_of_expr (exprs_of_file file))

let rec exectree_of_file : string -> string -> exectree =
  fun dir file ->
    let canon_file = canon_of_R_file dir file in
    let (f, opts) = cats_of_file canon_file in
    let nodelist =
        List.map (fun c -> match c with
                   | OptA child_file ->
                      let child_tree = exectree_of_file in
                      let canon_child = canon_of_R_file dir child_file in
                        (exectree_of_file dir canon_child)
                   | OptB expr -> ExprLeaf (f, expr)) opts in
      ExprNode (f, nodelist)

let rec linearization_of_exectree :
  exectree -> string list * (string * expr) list =
  fun tree ->
    match tree with
      | ExprLeaf (file, expr) -> ([], [(file, expr)])
      | ExprNode (file, currs) ->
          let level = map linearization_of_exectree currs in
          let (files, exprs) =
              List.fold_left (fun (fs, es) (cfs, ces) -> (fs @ cfs, es @ ces))
                             ([], []) level in
            (file :: files, exprs)

let linearize_source :
  string -> string -> string list * (string * expr) list =
  fun dir file ->
    linearization_of_exectree (exectree_of_file dir file)

let dump_file_linearization : string -> string -> unit =
  fun dir file ->
    let (files, exprs) = linearize_source dir file in
      print_string "--- files:";
      print_newline ();
      map (fun f -> print_string f; print_newline ()) files;
      print_string "--- exprs:";
      print_newline ();
      map (fun (f, e) -> print_string ("[" ^ f ^ "] ");
                         print_string (string_of_expr e);
                         print_newline ()) exprs;
      print_string "--- end dump";
      print_newline ();;


(*
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
    let exprs = exprs_of_file (canon_of_R_file dir file) in
    let deps = concat (map source_call_of_expr exprs) in
      map (fun f -> canon_of_R_file dir f) deps

let rec dependency_graph_list :
  string -> string -> StringSet.t -> string list * StringSet.t =
  fun dir file set ->
    let canon_name = canon_of_R_file dir file in
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

*)

let inj_binds_to_env_heap : (ident * expr) list -> memref -> heap -> heap =
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

