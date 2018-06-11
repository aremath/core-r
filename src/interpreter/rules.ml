
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


(* Double arrow reduction relations (cf Fig 3) *)

let rule_Exp : state -> state option =
  fun state -> match stack_pop state.stack with
    | None -> None
    | _ -> None

(* Promise Evaluation *)
let rule_ForceP : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (MemRef mem, env, stack2) -> (match heap_find mem state.heap with
      | Some (PromiseObj (p_expr, p_env)) ->
          let top_slot = UpdateSlot mem in
          let bot_slot = ExprSlot (p_expr, p_env) in
            Some { state with stack = stack_push top_slot
                                      (stack_push bot_slot stack2) }
      | _ -> None)
    | _ -> None

let rule_ForceF : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (LambdaApp (f_expr, args), env, stack2) ->
        let top_slot = ExprSlot (f_expr, env) in
        let bot_slot = ArgsSlot (args, env) in
          Some { state with stack = stack_push top_slot
                                    (stack_push bot_slot stack2) }
    | _ -> None


(* Single arrow expression manipulations (cf Fig 5) *)
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
    | Some (Assign (Const (Str str), expr), env, stack2) ->
        let slot = ExprSlot (Ident { default_id with name = str }, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None


(* Super assignment *)
let rule_DAss : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (SuperAssign _, _, _) -> None
    | _ -> None

(* Array access *)
let rule_Get1 : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (ArraySub (array_expr, args), env, _) ->
        let top_slot = ExprSlot (array_expr, env) in
        let bot_slot = ArraySubSlot (None, [], [], None, args, env) in
          Some { state with stack = stack_push top_slot
                                    (stack_push bot_slot state.stack) }
    | _ -> None

let rule_Get2 : state -> state option =
  fun state -> match stack_pop state.stack with
    | Some (ArraySubSlot (Some arr, oks, n_oks, None, top :: todos, env),
            stack2) -> (match id_expr_of_arg top with
      | None -> None
      | Some (o_id, expr) ->
          let top_slot = ExprSlot (expr, env) in
          let bot_slot =
              ArraySubSlot (Some arr, oks, n_oks, o_id, todos, env) in
            Some { state with stack = stack_push top_slot
                                      (stack_push bot_slot stack2) })
    | _ -> None

let rule_Get3 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ExprSlot (MemRef mem, env),
            ArraySubSlot (None, [], [], None, todos, _),
            stack2) ->
        let slot = ArraySubSlot (Some mem, [], [], None, todos, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None

let rule_Get4 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ExprSlot (MemRef mem, env),
            ArraySubSlot (Some arr, oks, n_oks, None, todos, _),
            stack2) ->
        let oks2 = mem :: oks in
        let slot = ArraySubSlot (Some arr, oks2, n_oks, None, todos, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None

let rule_Get5 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ExprSlot (MemRef mem, env),
            ArraySubSlot (Some arr, oks, n_oks, Some id, todos, _),
            stack2) ->
        let n_oks2 = (id, mem) :: n_oks in
        let slot =  ArraySubSlot (Some arr, oks, n_oks2, None, todos, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None

let rule_Get6 : state -> state option =
  fun state -> match stack_pop state.stack with
    | Some (ArraySubSlot (Some arr, oks, n_oks, None, [], env),
            stack2) ->
        None (* MORE DETAIL GOES HERE ABOUT ARRAY ACCESSING AND STUFF *)
    | _ -> None



