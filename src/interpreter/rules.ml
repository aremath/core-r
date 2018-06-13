
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

let id_variadic : ident =
  id_of_string "..."

let pair_first : 'a * 'b -> 'a =
  fun (a, b) -> a

type ('a , 'b) either =
    OptA of 'a
  | OptB of 'b

let rec split_eithers : (('a , 'b) either) list -> ('a list) * ('b list) =
  fun eithers -> match eithers with
    | [] -> ([], [])
    | (OptA a :: tail) -> 
        let (oas, obs) = split_eithers tail in
          (a :: oas, obs)
    | (OptB b :: tail) ->
        let (oas, obs) = split_eithers tail in
          (oas, b :: obs)

let rec pull_args :
  arg list -> env -> heap -> ((expr, (ident * expr)) either) list =
  fun args env heap -> match args with
    | [] -> []
    | (Arg expr :: tail) -> OptA expr :: pull_args tail env heap
    | (Named (id, expr) :: tail) -> OptB (id, expr) :: pull_args tail env heap
    | (VarArg :: tail) -> match env_find id_variadic env heap with
      | None -> []
      | Some mem -> match heap_find mem heap with
        | Some (DataObj (RefArray v_mems, _)) ->
            let mem_args = List.map (fun m -> OptA (MemRef m)) v_mems in
              mem_args @ pull_args tail env heap
        | _ -> [] (* WRONG STUFF HERE *)

let rec ids_contains_id : ident list -> ident -> bool =
  fun ids id -> match ids with
    | [] -> false
    | (hd :: tail) -> hd.name = id.name || ids_contains_id tail id

let rec remove_used_params : param list -> ident list -> param list =
  fun params args -> match params with
    | [] -> []
    | (Param id :: tail) ->
        if ids_contains_id args id
          then remove_used_params tail args
          else Param id :: remove_used_params tail args
    | (Default (id, expr) :: tail) ->
        if ids_contains_id args id
          then remove_used_params tail args
          else Default (id, expr) :: remove_used_params tail args
    | (VarParam :: tail) -> VarParam :: remove_used_params tail args

let rec get_default_params : param list -> (ident * expr) list =
  fun params -> match params with
    | [] -> []
    | (Param _ :: tail) -> get_default_params tail
    | (VarParam :: tail) -> get_default_params tail
    | (Default (id, expr) :: tail) -> (id, expr) :: get_default_params tail

let rec match_expr_args :
  param list -> expr list -> (ident * expr) list * (expr list) =
  fun params args -> match (params, args) with
    | ([], _) -> ([], []) (* OH NO?? *)
    | (_, []) -> (get_default_params params, [])
    | (VarParam :: tail, _) -> (get_default_params tail, args)
    | (Param id :: p_tail, arg :: a_tail) ->
        let (pairs, vars) = match_expr_args p_tail a_tail in
          ((id, arg) :: pairs, vars)
    | (Default (id, _) :: p_tail, arg :: a_tail) ->
        let (pairs, vars) = match_expr_args p_tail a_tail in
          ((id, arg) :: pairs, vars)

(* Oh god I really hope this function works, I've spent too much time here *)
let match_lambda_app :
  param list -> arg list -> env -> heap -> (ident * expr) list * expr list =
  fun params args env heap ->
    let (expr_args, nameds) = split_eithers (pull_args args env heap) in
    let un_params = remove_used_params params (List.map pair_first nameds) in
    let (positionals, variadics) = match_expr_args un_params expr_args in
      (nameds @ positionals, variadics)

(* Double arrow reduction relations (cf Fig 3) *)

(*
let rule_Exp : state -> state option =
  fun state -> match stack_pop state.stack with
    | None -> None
    | _ -> None
*)

(* Promise Evaluation *)
let rule_ForceP : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (MemRef p_mem), c_env_mem, c_stack2) ->
        (match heap_find p_mem state.heap with
          | Some (PromiseObj (p_expr, p_env_mem)) ->
              let p_frame = { frame_default with
                                env_mem = p_env_mem;
                                slot = EvalSlot p_expr } in
              let c_frame = { frame_default with
                                slot = UpdateSlot p_mem } in
                Some { state with
                         stack = stack_push p_frame
                                 (stack_push c_frame c_stack2) }
          | _ -> None)
    | _ -> None


(* Force function *)
let rule_ForceF : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (LambdaApp (fn, args)), c_env_mem, c_stack2) ->
        let f_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = EvalSlot fn } in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ArgsSlot args } in
          Some { state with
                   stack = stack_push f_frame
                           (stack_push c_frame c_stack2) }
    | _ -> None


(* Technically this rule doesn't even ... matter???
   Because we ``return'' everything through a pointer anyways *)
let rule_GetF : state -> state option =
  fun state ->
    None


let rule_InvF : state -> state option =
  fun state -> match stack_pop_v_2 state.stack with
    | Some (ReturnSlot f_mem, _,
            ArgsSlot args, c_env_mem,
            c_stack2) -> (match heap_find f_mem state.heap with
      | Some (DataObj (FuncVal (f_params, f_body, f_env_mem), _)) -> None
      | _ -> None)
    | _ -> None


(* Single arrow expression manipulations (cf Fig 5) *)

let rule_Const : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (Const const), _, c_stack2) ->
        let (const_mem, heap2) = heap_alloc_const const state.heap in
        let c_frame = { frame_default with
                          slot = ReturnSlot const_mem } in
          Some { state with
                   heap = heap2;
                   stack = stack_push c_frame c_stack2 }
    | _ -> None

(* Function Definition *)
let rule_Fun : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (LambdaAbs (params, expr)), c_env_mem, c_stack2) ->
        let data = DataObj (FuncVal (params, expr, c_env_mem), []) in
        let (f_mem, heap2) = heap_alloc data state.heap in
        let c_frame = { frame_default with
                          slot = ReturnSlot f_mem } in
          Some { state with
                   heap = heap2;
                   stack = stack_push c_frame c_stack2 }
    | _ -> None


(* Symbol. Actual search code in language/support.ml *)
let rule_Find : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (Ident id), c_env_mem, c_stack2) ->
        (match env_mem_find id c_env_mem state.heap with
          | None -> None
          | Some mem ->
              let c_frame = { frame_default with
                                slot = EvalSlot (MemRef mem) } in
                Some { state with
                         stack = stack_push c_frame c_stack2 })
    | _ -> None


(* Promise Indirection: shortcut when a promise pointer points to a pointer *)
let rule_GetP : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (MemRef p_mem), c_frame2, c_stack2) ->
        (match heap_find p_mem state.heap with
          | Some (PromiseObj (MemRef p_mem2, _)) ->
              let c_frame = { frame_default with
                                slot = EvalSlot (MemRef p_mem2) } in
                Some { state with
                         stack = stack_push c_frame c_stack2 }
          | _ -> None)
    | _ -> None


(* Assignment *)
let rule_AssId : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (Assign (Ident id, expr)), c_env_mem, c_stack2) ->
        let prom = PromiseObj (expr, c_env_mem) in
        let (p_mem, heap2) = heap_alloc prom state.heap in
          (match env_mem_add id p_mem c_env_mem heap2 with
            | None -> None
            | Some heap3 ->
                let p_frame = { frame_default with
                                  slot = EvalSlot (MemRef p_mem) } in
                let c_frame = { frame_default with
                                  slot = UpdateSlot p_mem } in
                  Some { state with
                           heap = heap3;
                           stack = stack_push p_frame
                                   (stack_push c_frame c_stack2) })
    | _ -> None


(* Super assignment *)
let rule_DAss : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (Assign (Ident id, expr)), c_env_mem, c_stack2) ->
        let prom = PromiseObj (expr, c_env_mem) in
        let (p_mem, heap2) = heap_alloc prom state.heap in
          (match heap_find c_env_mem state.heap with
            | Some (EnvObj env) ->
                let parent_mem = (match env.parent_mem with
                                    | None -> c_env_mem
                                    | Some parent_mem -> parent_mem) in
                  (match env_mem_add id p_mem parent_mem heap2 with
                    | None -> None
                    | Some heap3 ->
                        let p_frame = { frame_default with
                                          slot = EvalSlot (MemRef p_mem) } in
                        let c_frame = { frame_default with
                                          slot = UpdateSlot p_mem } in
                          Some { state with
                                   heap = heap3;
                                   stack = stack_push p_frame
                                           (stack_push c_frame c_stack2) })
            | _ -> None)
    | _ -> None


let rule_AssStr : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (Assign (Const (Str (Some str)), expr)),
            c_env_mem, c_stack2) ->
        let c_slot =
            EvalSlot (Assign (Ident { id_default with name = str }, expr)) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push c_frame c_stack2 }
    | _ -> None

let rule_DAssStr : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (SuperAssign (Const (Str (Some str)), expr)),
            c_env_mem, c_stack2) ->
        let c_slot =
            EvalSlot (SuperAssign (Ident { id_default with
                                             name = str }, expr)) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push c_frame c_stack2 }
    | _ -> None



(* Array access *)
let rule_Get1 : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (EvalSlot (ArraySub (arr, args)), c_env_mem, c_stack2) ->
        let a_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = EvalSlot arr } in
        let c_slot = ArraySubSlot (None, [], [], None, args) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push a_frame
                           (stack_push c_frame c_stack2 ) }
    | _ -> None

let rule_Get2 : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (ArraySubSlot (Some arr, oks, noks, None, arg :: tail),
            c_env_mem, c_stack2) ->
        (match id_expr_of_arg arg with
          | None -> None
          | Some (o_id, a_expr) ->
              let a_frame = { frame_default with
                                env_mem = c_env_mem;
                                slot = EvalSlot a_expr } in
              let c_slot = ArraySubSlot (Some arr, oks, noks, o_id, tail) in
              let c_frame = { frame_default with
                                env_mem = c_env_mem;
                                slot = c_slot } in
                Some { state with
                         stack = stack_push a_frame
                                 (stack_push c_frame c_stack2) })
    | _ -> None

let rule_Get3 : state -> state option =
  fun state -> match stack_pop_v_2 state.stack with
    | Some (ReturnSlot mem, _,
            ArraySubSlot (None, [], [], None, args), c_env_mem,
            c_stack2) ->
        let c_slot = ArraySubSlot (Some mem, [], [], None, args) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push c_frame c_stack2 }
    | _ -> None

let rule_Get4 : state -> state option =
  fun state -> match stack_pop_v_2 state.stack with
    | Some (ReturnSlot mem, _,
            ArraySubSlot (Some arr, oks, noks, None, args), c_env_mem,
            c_stack2) ->
        let oks2 = mem :: oks in
        let c_slot = ArraySubSlot (Some arr, oks2, noks, None, args) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push c_frame c_stack2 }
    | _ -> None

let rule_Get5 : state -> state option =
  fun state -> match stack_pop_v_2 state.stack with
    | Some (ReturnSlot mem, _,
            ArraySubSlot (Some arr, oks, noks, Some id, args), c_env_mem,
            c_stack2) ->
        let noks2 = (id, mem) :: noks in
        let c_slot = ArraySubSlot (Some arr, oks, noks2, None, args) in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = c_slot } in
          Some { state with
                   stack = stack_push c_frame c_stack2 }
    | _ -> None

let rule_Get6 : state -> state option =
  fun state -> match stack_pop_v state.stack with
    | Some (ArraySubSlot (Some arr, oks, noks, None, []), c_env_mem,
            c_stack2) ->
        None
    | _ -> None


