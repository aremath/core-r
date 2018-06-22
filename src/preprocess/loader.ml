
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
  | OptA of 'a
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
                   | OptA child_file -> exectree_of_file dir child_file
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

let dump_file_ast : string -> unit =
  fun file ->
    let absyn = parseFile file in
    print_endline (Rast.string_of_program absyn)

let dump_file_linearization : string -> string -> unit =
  fun dir file ->
    let (files, exprs) = linearize_source dir file in
      print_endline "--- files:";
      map (fun f -> print_string f; print_newline ()) files;
      print_endline "--- exprs:";
      map (fun (f, e) -> print_string ("[" ^ (*f ^ *) "] ");
                         print_endline (string_of_expr e)) exprs;
      print_endline "--- end dump";;

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

(* The ones closer to the tail are closer to the super duper env *)
let alloc_file_envs :
  string list -> memref -> heap -> (string * memref) list * heap =
  fun files sup_env_mem heap ->
    if length files = 0 then
      ([], heap)
    else
      let envs = map (fun f -> T.DataObj (T.EnvVal T.env_empty,
                                          T.attrs_empty)) files in
      let (mems, heap2) = T.heap_alloc_list envs heap in
      let pred_mems = sup_env_mem :: mems in
      let pairs = combine mems (rev (tl (rev pred_mems))) in
      let heap3 = fold_left (fun h (e, s) -> match T.heap_find e h with
                            | Some (DataObj (EnvVal env, attrs)) ->
                                let env2 = { env with pred_mem = s } in
                                  T.heap_add e (DataObj (EnvVal env2, attrs)) h
                            | _ -> failwith ("alloc_file_envs: " ^
                                                string_of_memref e)
                          ) heap2 pairs in
        (combine files (rev mems), heap3)



(* Inject heap1 into heap2 *)
let merge_heap : heap -> heap -> heap =
  fun heap1 heap2 ->
    inj_heap_list (T.binds_of_heap heap1) heap2


let load_file : string -> string -> env * heap =
  fun dir file -> (T.env_empty, T.heap_empty)

