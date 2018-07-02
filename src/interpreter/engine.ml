
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

let is_state_complete : state -> bool =
  fun state -> match (stack_pop_v state.stack,
                      stack_pop_v2 state.stack) with
    | (Some (ReturnSlot _, _, _), None) -> true
    | _ -> false

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

let rec run_n : int -> passresult -> passresult =
  fun n (comps, errs, incomps) ->
    if n <= 0 then
      (comps, errs, incomps)
    else
      let (comps2, errs2, incomps2) = run_pass incomps in
        run_n (n - 1) (comps2 @ comps, errs2 @ errs, incomps @ incomps2)

let rec run_n_hist :
  int -> passresult list -> (rule list * state) list -> passresult list =
  fun n hist todos ->
    if n <= 0 then
      hist @ [([], [], todos)]
    else
      let (comps2, errs2, incomps2) = run_pass todos in
        run_n_hist (n - 1) (hist @ [(comps2, errs2, incomps2)]) incomps2


