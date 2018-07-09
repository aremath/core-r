
open Syntax
open Support
open Rules
open Native_calls
open List

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

let get_completed_result : state -> (value * attributes) option =
  fun state ->
    match (stack_pop_v state.stack, stack_pop_v2 state.stack) with
    | (Some (ReturnSlot mem, _, _), None) ->
      (match heap_find mem state.heap with
      | Some (DataObj (value, attrs)) -> Some (value, attrs)
      | _ -> None)
    | _ -> None

let is_state_complete : state -> bool =
  fun state ->
    match get_completed_result state with
    | Some _ -> true
    | None -> false

let is_state_not_complete : state -> bool =
  fun state -> not (is_state_complete state)

type passresult =
  (rule list * state) list *
  (rule list * state) list *
  (rule list * state) list

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

let rec do_n : int -> passresult -> passresult =
  fun n (comps, errs, incomps) ->
    if n <= 0 then
      (comps, errs, incomps)
    else
      (print_endline ("hue");
      let (comps2, errs2, incomps2) = run_pass incomps in
        do_n (n - 1) (comps2 @ comps, errs2 @ errs, incomps @ incomps2));;

let run_n : int -> state list -> passresult =
  fun n inits ->
    let raws = map (fun s -> ([], s)) inits in
    let ticks = ref n in
    let comps = ref [] in 
    let errs = ref [] in
    let incomps = ref raws in
      begin
        while (!ticks >= 0) do
          print_endline ("boo!");
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

let rec do_hist_n :
  int -> passresult list -> (rule list * state) list -> passresult list =
  fun n hist todos ->
    if (n <= 0) || (List.length todos = 0) then
      hist @ [([], [], todos)]
    else
      let (comps2, errs2, incomps2) = run_pass todos in
            do_hist_n (n - 1) (hist @ [(comps2, errs2, incomps2)]) incomps2

let run_n_hist : int -> state list -> passresult list =
  fun n inits ->
    let raws = map (fun s -> ([], s)) inits in
      do_hist_n n [([], [], raws)] raws


(*
let get_completed_after_n :
  int -> passresult list -> (rule list * state) -> passresult list =
*)

