
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
  fun state -> match stack_pop_e state.stack with
    | Some (MemRef mem, env, _) -> (match heap_find_opt mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          Some {state with
            stack = stack_push (ExprSlot (p_expr, p_env)) state.stack}
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations *)
let rule_Const : state -> state option =
  fun st -> match stack_pop_e st.stack with
    | Some ((Const c), env, stack') ->
        (let (mem, heap') = heap_alloc_const c st.heap in
         let slot = ExprSlot ((MemRef mem), env) in
           Some {st with heap = heap';
                         stack = stack_push slot stack'})
    | _ -> None

let rule_Fun : state -> state option =
  fun st -> match stack_pop_e with 
    | _ -> None
    | _ -> None


