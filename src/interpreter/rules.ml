
open Syntax
open Support

type rule =
    RuleExp
  | RuleForceP
  | RuleForceF
  | RuleGetF
  | RuleInvF
  | RuleRetP
  | RuleRetF

  | RuleGetF1
  | RuleGetF2
  | RuleGetF3
  | RuleGetF4
  | RuleGetF5
  | RuleSplit1
  | RuleSplit2
  | RuleSplit3
  | RuleArgs
  | RuleArgs1
  | RuleArgs2
  | RuleArgs3
  | RuleArgs4
  | RuleArgs5

  | RuleNum
  | RuleStr
  | RuleFun
  | RuleFind
  | RuleGetP
  | RuleAss
  | RuleDAss
  | RuleGet
  | RuleSetL
  | RuleSetG
  | RuleGetA
  | RuleReplA
  | RuleSetA
  | RuleSetB


let rule_Exp : state -> state option =
  fun state -> match stack_pop state.stack with
    | None -> None
    | _ -> None


let rule_ForceP : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (MemRef mem, env, _) -> (match heap_find_opt mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          Some {state with
            stack = stack_push {expr=p_expr; env=p_env} state.stack}
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations *)
let rule_Num : state -> state option =
  fun st -> match stack_pop_v st.stack with
    | Some (Const (Num n), _, _) ->
        (let (mem', state') = fresh_memref st in
         let obj = DataObj (NumArray [n], []) in
          Some {state' with heap = heap_add mem' obj state'.heap})
    | _ -> None

let rule_Str : state -> state option =
  fun st -> match stack_pop_v st.stack with
    | Some (Const (Str s), _, _) ->
        (let (mem', state') = fresh_memref st in
         let obj = DataObj (StrArray [s], []) in
          Some {state' with heap = heap_add mem' obj state'.heap})
    | _ -> None


