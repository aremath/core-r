
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
(* LIkely wrong!!!*)
let rule_ForceP : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (MemRef mem, env, _) -> (match heap_find mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          let slot = ExprSlot (p_expr, p_env) in
            Some { state with stack = stack_push slot state.stack }
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations *)
let rule_Const : state -> state option =
  (* pop the stack frame *)
  fun state -> match stack_pop_expr state.stack with
    (* if it's a constant *)
    | Some ((Const c), env, stack2) ->
        (* allocate space for it on the heap *)
        (let (mem, heap2) = heap_alloc_const c state.heap in
        (* create a new slot on the stack with the pointer to where it now
           lives on the heap *)
         let slot = ExprSlot (MemRef mem, env) in
           (* push that slot onto the stack *)
           Some { state with heap = heap2;
                             stack = stack_push slot stack2 })
    | _ -> None

(* Function Definition *)
let rule_Fun : state -> state option =
  fun state -> match stack_pop_expr state.stack with 
    | Some ((LambdaAbs (params, expr)), env, stack2) ->
        (let obj = DataObj (FuncVal (params, expr, env), []) in
         let (mem, heap2) = heap_alloc obj state.heap in
         let slot = ExprSlot (MemRef mem, env) in
           Some { state with heap = heap2;
                             stack = stack_push slot stack2 })
    | _ -> None

(* Symbol. Actual search code in language/support.ml *)
let rule_Find : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (Ident id, env, stack2) -> (match env_find id env state.heap with
      (* search for the symbol in the current environment *)
      | Some mem -> (* push its address to the stack *)
          let slot = ExprSlot (MemRef mem, env) in
            Some { state with stack = stack_push slot stack2 }
      | _ -> None)
    |_ -> None

(* Promise Indirection: a shortcut when a promise pointer points to a pointer *)
let rule_GetP : state -> state option = 
  fun state -> match stack_pop_expr state.stack with
    | Some (MemRef mem, env, stack2) -> (match heap_find mem state.heap with
        | Some (PromiseObj (MemRef p_mem, p_env)) ->
            let slot = ExprSlot (MemRef p_mem, p_env) in (* TODO: verify *)
              Some { state with stack = stack_push slot stack2 }
        | _ -> None)
    | _ -> None

(* Assignment *)
let rule_AssId : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (Assign (Ident id, expr), env, stack2) ->
        (let obj = PromiseObj (expr, env) in
         let (mem, heap2) = heap_alloc obj state.heap in
           match env_add_map id mem env heap2 with
             | None -> None
             | Some (env2, heap3) ->
                 let slot = ExprSlot (MemRef mem, env2) in
                   Some { state with stack = stack_push slot stack2;
                                     heap = heap3 })
    | _ -> None

let rule_AssStr : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (Assign (Const (Str (Some str)), expr), env, stack2) ->
        let slot = ExprSlot (Ident { default_id with name = str }, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None


(* Super assignment *)
let rule_DAss : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (SuperAssign _, _ , _) -> None
    | _ -> None

(* Array access *)
let rule_Get1 : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (ArraySub (array_expr, arg_exprs), env, _) ->
        let slot = ArraySubSlot (None, [], arg_exprs) in
          Some { state with stack = stack_push slot state.stack }
    | _ -> None


let rule_Get2 : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (MemRef mem, env, stack2) -> (match stack_pop stack2 with
      | Some (ArraySubSlot (None, [], a_args), stack3) ->
          let slot = ArraySubSlot (Some mem, [], a_args) in
            Some { state with stack = stack_push slot stack3 }
      | _ -> None)
    | _ -> None


