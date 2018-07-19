
open Syntax
open Support
open Rules
open Native_calls
open Loader
open Smttrans
open Smt2
open Solver
open Smt

open Stepper

open List
open Printf
open Sys

type redresult =
  | ReductionOkay of rule * state list
  | MultipleRulesMatch of (rule * state list) list
  | NoRulesMatch

let step_rule : state -> redresult =
  fun state ->
    let res = map (fun (r, f) -> (r, f state)) rule_table in
      match res with
      | [] -> NoRulesMatch
      | _ -> match filter (fun (r, ss) -> length ss > 0) res with
        | [] -> NoRulesMatch
        | ((r, ss) :: []) -> ReductionOkay (r, ss)
        | toomuch -> MultipleRulesMatch toomuch

let get_state_result : state -> (value * attributes) option =
  fun state ->
    match (stack_pop_v state.stack, stack_pop_v2 state.stack) with
    | (Some (ReturnSlot mem, _, _), None) ->
      (match heap_find mem state.heap with
      | Some (DataObj (value, attrs)) -> Some (value, attrs)
      | _ -> None)
    | _ -> None

let is_state_complete : state -> bool =
  fun state ->
    match get_state_result state with
    | Some _ -> true
    | None -> false

let is_state_not_complete : state -> bool =
  fun state -> not (is_state_complete state)


let run_pass : (rule list * state) list -> passresult =
  fun states ->
    let comps = filter (fun (a, b) -> is_state_complete b) states in
    let incomps = filter (fun (a, b) -> is_state_not_complete b) states in
      fold_left
        (fun (c, e, i) (hist, st) ->
          match step_rule st with
          | NoRulesMatch ->
              print_endline ("no rules matched at state " ^
                              string_of_int st.unique);
              (c, (hist, st) :: e, i)
          | ReductionOkay (r, sts) ->
              let csts = map (fun s -> (r :: hist, s))
                             (filter is_state_complete sts) in
              let ncsts = map (fun s -> (r :: hist, s))
                              (filter is_state_not_complete sts) in
                (csts @ c, e, ncsts @ i)
          | MultipleRulesMatch ress ->
              print_endline ("multiple rules match at state " ^
                             string_of_int st.unique);
              print_endline ("pretending as though nothing happened!");
              let expanded =
                    concat (map (fun (r, ss) ->
                                  map (fun s -> (r :: hist, s)) ss)
                                ress) in
              let csts = filter (fun (r, s) -> is_state_complete s)
                                 expanded in
              let ncsts = filter (fun (r, s) -> is_state_not_complete s)
                                  expanded in
                (csts @ c, e, ncsts @ i))
        (comps, [], []) incomps

(* Different versions of run functions for debugging, etc *)

let run_n : int -> state list -> passresult =
  fun n inits ->
    let raws = map (fun s -> ([], s)) inits in
    let ticks = ref n in
    let comps = ref [] in 
    let errs = ref [] in
    let incomps = ref raws in
      begin
        while (!ticks > 0) do
          if List.length !incomps <= 0 then
            begin ticks := -1; end
          else
            begin
              let (comps2, errs2, incomps2) = run_pass !incomps in
              comps := comps2 @ !comps;
              errs := errs2 @ !errs;
              incomps := incomps2;
              ticks := !ticks - 1
            end
        done;
        (!comps, !errs, !incomps)
      end

let run_n_hist : int -> state list -> passresult list =
  fun n inits ->
    let raws = map (fun s -> ([], s)) inits in
    let ticks = ref n in
    let hist = ref [([], [], raws)] in
    let incomps = ref raws in
      begin
        while (!ticks > 0) do
          if List.length !incomps <= 0 then
            begin ticks := -1; end
          else
            begin
              let (comps2, errs2, incomps2) = run_pass !incomps in
              hist := !hist @ [(comps2, errs2, incomps2)];
              incomps := incomps2;
              ticks := !ticks - 1;
            end
        done;
        !hist
      end

let run_n_first_result :
  int -> state list ->  (value * attributes) option =
  fun n inits ->
    let (comps, errs, incomps) = run_n n inits in
    let ress = map (fun (_, s) -> get_state_result s) comps in
      match ress with
      | (res :: ress_tail) ->
          begin
            let len = List.length ress_tail in
            if (len > 0) then
              print_endline ("omitting " ^ string_of_int len ^ " results");
            res
          end
      | _ -> None

let load_run_n_first_result : string -> int -> (value * attributes) option =
  fun file n ->
    let state = load_file_guess file in
      run_n_first_result n [state]

let solve_state : state -> string =
  fun state ->
    let stmts = smtcmd_list_of_state state in
    let smt2 = smt2_of_smtcmd_list stmts in
      run_z3 smt2

let rw_perms : unit -> int =
  fun _ -> 0o666

(* Assumes a canonicalized directory *)
let dump_solve_state : string -> state -> unit =
  fun dir state ->
    let res = solve_state state in
    (* let _ = if file_exists dir then mkdir dir (rw_perms ()) in *)
    let _ = if file_exists dir then command ("mkdir " ^ dir) else -1 in
    let dump_file = dir ^ "/state-" ^ string_of_int state.unique in
    let dump_out = open_out dump_file in
    let _ = fprintf dump_out "%s" res in
    let _ = close_out dump_out in
      ()

(* Assumes a canonicalized directory *)
let dump_solve_passresult : string -> passresult -> unit =
  fun dir (comps, errs, incomps) ->
    (* let _ = if not (file_exists dir) then
                  mkdir dir (rw_perms ()) in *)
    let _ = if not (file_exists dir) then command ("mkdir " ^ dir) else -1 in

    let comps_dir = dir ^ "/comps" in
    (* let _ = if not (file_exists comps_dir) then
                  mkdir comps_dir (rw_perms ()) in *)
    let _ = if not (file_exists comps_dir) then
              command ("mkdir " ^ comps_dir) else -1 in
    let _ = map (fun (_, s) -> dump_solve_state comps_dir s) comps in

    let errs_dir = dir ^ "/errs" in
    (* let _ = if not (file_exists errs_dir) then
                  mkdir errs_dir (rw_perms ()) in *)
    let _ = if not (file_exists errs_dir) then
              command ("mkdir " ^ errs_dir) else -1 in
    let _ = map (fun (_, s) -> dump_solve_state errs_dir s) errs in

    let incomps_dir = dir ^ "/incomps" in
    (* let _ = if not (file_exists incomps_dir) then
                  mkdir incomps_dir (rw_perms ()) in *)
    let _ = if not (file_exists incomps_dir) then
              command ("mkdir " ^ incomps_dir) else -1 in
    let _ = map (fun (_, s) -> dump_solve_state incomps_dir s) incomps in
      ()


let inj_symbolics : unit list -> state -> state =
  fun _ s -> s

