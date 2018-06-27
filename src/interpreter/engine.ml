
open Syntax
open Support
open Rules
open Native
open List

type redresult =
  | ReductionOkay of rule * list state
  | MultipleRulesMatch of (rule * list state) list
  | NoRulesMatch

let step_rule : state -> (rule, list state) option =
let step_rule : state -> redresult =
  fun state ->
    let res = map (fun (r, f) -> (r, f state)) rule_table in
      match concat res with
      | [] -> NoRulesMatch state
      | _ -> match filter (fun l -> length l > 0) res in
        | [] -> NoRulesMatch
        | (res :: []) -> ReductionOkay res
        | toomuch -> MultipleRulesMatch toomuch

let is_state_complete : state -> bool =
  fun state -> match (stack_pop state.stack, stack_pop_v2) with
    | (Some _, None) -> true
    | _ -> false

let is_state_not_complete : state -> bool
  fun state -> not (is_state_complete state)

let run_pass : (list rule * state) list -> (list rule * state) list *
                                           (list rule * state) list *
                                           (list rule * state) list
  fun states ->
    let comps = filter is_state_complete states in
    let incomps = filter is_state_not_complete states in
    let rule_apps = fold_left
          (fun (c, e, i) (hist, st) ->
            match step_rule st with
            | NoRulesMatch (c, (hist, st) :: e, i)
            | ReductionOkay (r, sts) ->
                let csts = map (fun s -> (r :: hist, s))
                               (filter is_state_complete sts) in
                let ncsts = map (fun s -> (r :: hist, s))
                                (filter is_state_not_complete sts) in
                  (csts @ c, e, ncsts @ i)
            | MultipleRulesMatch ress ->
                print_endline ("multiple rules match at state with unique " ^
                               string_of_int state.unique);
                print_endline ("pretending as though nothing happened!");
                let expanded =
                      concat (map (fun (r, ss) ->
                                    map (fun s -> (r :: hist, s)) ss)
                                  ress) in
                let csts = filter (fun (r, s) -> is_state_complete s)
                                   expanded in
                let ncsts = filter (fun (r, s) -> is_state_not_complete s)
                                    expanded in
                  (csts @ c, e, ncsts @ i)


