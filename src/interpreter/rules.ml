
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

(*
let rule_Exp : state -> state option =
  fun state -> match stack_pop state.stack with
    | None -> None
    | _ -> None
*)

(* Promise Evaluation *)
let rule_ForceP : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (MemRef mem), c_frame2, c_stack2) ->
        (match heap_find mem state.state_heap with
          | Some (PromiseObj (p_expr, p_env)) ->
            let p_slot = EvalSlot p_expr in
            let p_frame = { frame_empty with frame_env = p_env;
                                             slot_list = [p_slot] } in
            let c_slot = UpdateSlot mem in
            let c_frame3 = frame_push c_slot c_frame2 in
              Some { state with
                       state_stack = stack_push p_frame
                                     (stack_push c_frame3 c_stack2) }
          | _ -> None)
    | _ -> None

(* Force function *)
let rule_ForceF : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (LambdaApp (f_expr, args)), c_frame2, c_stack2) ->
        let f_slot = EvalSlot f_expr in
        let c_slot = ArgsSlot args in
        let c_frame3 = frame_push f_slot (frame_push c_slot c_frame2) in
          Some { state with
                   state_stack = stack_push c_frame3 c_stack2 }
    | _ -> None

(* Technically this rule doesn't even ... matter???
   Because we ``return'' everything through a pointer anyways *)
let rule_GetF : state -> state option =
  fun state ->
    None

let rule_InvF : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some _ -> None
    | _ -> None


(* Single arrow expression manipulations (cf Fig 5) *)

let rule_const : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (Const const), c_frame2, c_stack2) ->
      let (mem, heap2) = heap_alloc_const const state.state_heap in
      let c_slot = ReturnSlot mem in
      let c_frame3 = frame_push c_slot c_frame2 in
        Some { state with
                 state_heap = heap2;
                 state_stack = stack_push c_frame3 c_stack2 }
    | _ -> None


(* Function Definition *)
let rule_Fun : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (LambdaAbs (params, expr)), c_frame2, c_stack2) ->
        let obj = DataObj (FuncVal (params, expr, c_frame2.frame_env), []) in
        let (mem, heap2) = heap_alloc obj state.state_heap in
        let c_slot = ReturnSlot mem in
        let c_frame3 = frame_push c_slot c_frame2 in
          Some { state with
                   state_heap = heap2;
                   state_stack = stack_push c_frame3 c_stack2 }
    | _ -> None

(* Symbol. Actual search code in language/support.ml *)
let rule_Find : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (Ident id), c_frame2, c_stack2) ->
        (match env_find id c_frame2.frame_env with
          | None -> None
          | Some mem ->
              let c_slot = EvalSlot (MemRef mem) in
              let c_frame3 = frame_push c_slot c_frame2 in
                Some { state with
                         state_stack = stack_push c_frame3 c_stack2 })
    | _ -> None


(* Promise Indirection: a shortcut when a promise pointer points to a pointer *)
let rule_GetP : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (MemRef mem), c_frame2, c_stack2) ->
        (match heap_find mem state.state_heap with
          | Some (PromiseObj (MemRef p_mem, _)) ->
              let c_slot = EvalSlot (MemRef p_mem) in
              let c_frame3 = frame_push c_slot c_frame2 in
                Some { state with
                         state_stack = stack_push c_frame3 c_stack2 }
          | _ -> None)
    | _ -> None

(* Assignment *)
let rule_AssId : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (Assign (Ident id, expr)), c_frame2, c_stack2) ->
        let obj = PromiseObj (expr, c_frame2.frame_env) in
        let (mem, heap2) = heap_alloc obj state.state_heap in
        let c_slot1 = EvalSlot (MemRef mem) in
        let c_slot2 = UpdateSlot mem in
        let c_frame_env2 = env_add id mem c_frame2.frame_env in
        let c_frame3 = frame_push c_slot1 (frame_push c_slot2 c_frame2) in
        let c_frame4 = { c_frame3 with frame_env = c_frame_env2 } in
          Some { state with
                   state_heap = heap2;
                   state_stack = stack_push c_frame4 c_stack2 }
    | _ -> None

let rule_AssStr : state -> state option =
  fun state -> match stack_pop_slot state.state_stack with
    | Some (EvalSlot (Assign (Const (Str (Some str)), expr)),
            c_frame2, c_stack2) ->
        let c_slot = EvalSlot (Assign (Ident { id_default with name = str },
                                       expr)) in
        let c_frame3 = frame_push c_slot c_frame2 in
          Some { state with
                   state_stack = stack_push c_frame3 c_stack2 }
    | _ -> None


(*

(* Super assignment *)
let rule_DAss : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (SuperAssign _, _, _) -> None
    | _ -> None

(* Array access *)
let rule_Get1 : state -> state option =
  fun state -> match stack_pop_expr state.stack with
    | Some (ArraySub (array_expr, args), env, _) ->
        let top_slot = EvalSlot (array_expr, env) in
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
          let top_slot = EvalSlot (expr, env) in
          let bot_slot =
              ArraySubSlot (Some arr, oks, n_oks, o_id, todos, env) in
            Some { state with stack = stack_push top_slot
                                      (stack_push bot_slot stack2) })
    | _ -> None

let rule_Get3 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ReturnSlot (mem, env),
            ArraySubSlot (None, [], [], None, todos, _),
            stack2) ->
        let slot = ArraySubSlot (Some mem, [], [], None, todos, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None

let rule_Get4 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ReturnSlot (mem, env),
            ArraySubSlot (Some arr, oks, n_oks, None, todos, _),
            stack2) ->
        let oks2 = mem :: oks in
        let slot = ArraySubSlot (Some arr, oks2, n_oks, None, todos, env) in
          Some { state with stack = stack_push slot stack2 }
    | _ -> None

let rule_Get5 : state -> state option =
  fun state -> match stack_pop_2 state.stack with
    | Some (ReturnSlot (mem, env),
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


*)

