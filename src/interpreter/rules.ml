
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
  fun state -> match stack_pop_expr state.stack with
    | Some (MemRef mem, env, _) -> (match heap_find_opt mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          Some {state with
            stack = stack_push (ExprSlot (p_expr, p_env)) state.stack}
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations *)
let rule_Const : state -> state option =
  (* pop the stack frame *)
  fun state -> match stack_pop_expr state.stack with
    (* if it's a constant *)
    | Some ((Const c), env, stack2) ->
        (* allocate space for it on the heap *)
        (let (mem, heap') = heap_alloc_const c state.heap in
        (* create a new slot on the stack with the pointer to where it now lives on the heap *)
         let slot = ExprSlot ((MemRef mem), env) in
           (* push that slot onto the stack *)
           Some {state with heap = heap';
                         stack = stack_push slot stack2})
    | _ -> None

(* Function Definition *)
let rule_Fun : state -> state option =
  fun state -> match stack_pop_expr state.stack with 
    | Some ((LambdaAbs (ps, expr)), env, stack2) ->
        (let (mem, heap') = heap_alloc
            (DataObj (FuncVal (ps, expr, env), [])) state.heap in
            let slot = ExprSlot ((MemRef mem), env) in
                Some {state with heap = heap';
                              stack = stack_push slot stack2}
        )
    | _ -> None

(* Symbol. Actual search code in language/support.ml *)
let rule_Find : state -> state option =
  fun state -> match stack_pop_expr state.stack with
  | Some ((Ident i), env, stack2) ->
    (* search for the symbol in the current environment *)
    begin match env_find_opt i env state.heap with
        | Some mem -> (* push its address to the stack *)
            let slot = ExprSlot ((MemRef mem), env) in
                Some {state with stack = stack_push slot stack2}
        | _ -> None
    end
  |_ -> None

(* Promise Indirection: a shortcut when a promise pointer points to a pointer *)
let rule_GetP : state -> state option = 
  fun state -> match stack_pop_expr state.stack with
  | Some ((MemRef mem), env, stack2) ->
    begin match heap_find_opt mem state.heap with
      | Some (PromiseObj ((MemRef mem2), env2)) ->
            let slot = ExprSlot ((MemRef mem2), env2) in (* TODO: verify *)
                Some {state with stack = stack_push slot stack2}
      |_ -> None
    end
  |_ -> None

(*
(* Assignment *)
let rule_Ass : state -> state option =
    fun state -> match stack_pop_expr state.stack with

*)
