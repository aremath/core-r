
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

(* Promise Evaluation *)
let rule_ForceP : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (MemRef mem, env, _) -> (match heap_find_opt mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          Some {state with
            stack = stack_push {expr = p_expr; env = p_env} state.stack}
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations *)
let rule_Const : state -> state option =
  (* pop the stack frame *)
  fun st -> match stack_pop_v st.stack with
    (* if it's a constant *)
    | Some ((Const c), env, stack') ->
        (* allocate space for it on the heap *)
        (let (mem, heap') = heap_alloc_const c st.heap in
        (* create a new slot on the stack with the pointer to where it now lives on the heap *)
         let slot = mk_slot (MemRef mem) env in
           (* push that slot onto the stack *)
           Some {st with heap = heap';
                         stack = stack_push slot stack'})
    | _ -> None

(* Function Definition *)
let rule_Fun : state -> state option =
  fun st -> match stack_pop_v st.stack with 
    | Some ((LambdaAbs (ps, expr)), env, stack') ->
        (let (mem, heap') = heap_alloc
            (DataObj (FuncVal (ps, expr, env), [])) st.heap in
            let slot = mk_slot (MemRef mem) env in
                Some {st with heap = heap';
                              stack = stack_push slot stack'}
        )
    | _ -> None

(* Symbol. Actual search code in language/support.ml *)
let rule_Find : state -> state option
  fun st -> match stack_pop_v st.stack with
  | Some ((Ident i), env, stack') ->
    (* search for the symbol in the current environment *)
    let mem = env_find_opt i env st.heap in
    (* push its address to the stack *)
    let slot = mk_slot (MemRef mem) env in
        Some {st with stack = stack_push slot stack'}
  |_ -> None

(* Promise Evaluation *)
let rule_GetP : state -> state option
  fun st -> match stack_pop_v st.stack with
  | Some ((MemRef mem), env, stack') ->
    

  |_ -> None
