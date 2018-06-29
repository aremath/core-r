
open List
open Syntax
open Support
open Natives
open Copy

type rule =
  | RuleForceP
  | RuleForceF
  | RuleGetF
  | RuleInvF
  | RuleNativeInvF

  | RuleConst
  | RuleFunc
  | RuleFind
  | RuleGetP

  | RuleUpdate
  | RuleAssId
  | RuleDAss
  | RuleAssStr
  | RuleDAssStr

  | RuleIfEval
  | RuleIfRet
  | RuleWhileEval
  | RuleWhileCondTrue
  | RuleWhileCondFalse
  | RuleWhileBodyDone
  | RuleBreak
  | RuleNext

  | RuleSeq
  | RuleObjAttrEval
  | RuleObjAttrObjRet
  | RuleObjAttrObjGet


let id_variadic : ident =
  id_of_rstring (rstring_of_string "...")

let pair_first : 'a * 'b -> 'a =
  fun (a, b) -> a

type ('a , 'b) either =
    OptA of 'a
  | OptB of 'b

let rec split_eithers : (('a , 'b) either) list -> ('a list) * ('b list) =
  fun eithers ->
    match eithers with
    | [] -> ([], [])
    | (OptA a :: e_tl) ->
        let (oas, obs) = split_eithers e_tl in
          (a :: oas, obs)
    | (OptB b :: e_tl) ->
        let (oas, obs) = split_eithers e_tl in
          (oas, b :: obs)

let expr_of_arg : arg -> expr =
  fun arg -> match arg with
    | Arg expr -> expr
    | Named (_, expr) -> expr
    | VarArg -> Ident id_variadic

let rec ids_contains_id : ident list -> ident -> bool =
  fun ids id ->
    match ids with
    | [] -> false
    | (hd :: ids_tl) -> hd.name = id.name || ids_contains_id ids_tl id

let rec get_default_params : param list -> (ident * const) list =
  fun params ->
    match params with
    | [] -> []
    | (Param _ :: params_tl) -> get_default_params params_tl
    | (VarParam :: params_tl) -> get_default_params params_tl
    | ((Default (id, Const const)) :: params_tl) ->
        (id, const) :: get_default_params params_tl
    (* This should not have happened in good param cases *)
    | ((Default _) :: params_tl) -> get_default_params params_tl

let rec pull_args :
  (arg * memref) list -> heap -> ((memref, (ident * memref)) either) list =
  fun args heap ->
    match args with
    | [] -> []
    | ((Arg _, mem) :: args_tl) ->
        OptA mem :: pull_args args_tl heap
    | ((Named (id, _), mem) :: args_tl) ->
        OptB (id, mem) :: pull_args args_tl heap
    | ((VarArg, mem) :: args_tl) ->
        match heap_find mem heap with
        | Some (DataObj (RefArray v_mems, _)) ->
          (map (fun m -> OptA m) v_mems) @ pull_args args_tl heap
        (*Something very wrong here, can't find variadic in heap!! *)
        | _ -> pull_args args_tl heap
          
let rec remove_used_params : param list -> ident list -> param list =
  fun params args ->
    match params with
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

let rec match_mems :
  param list -> memref list ->
    (ident * ((memref, const) either)) list * (memref list) =
  fun params mems ->
    match (params, mems) with
    | ([], _) -> ([], []) (* OH NO??? *)
    | (_, []) ->
      let defs = get_default_params params in
      let mods = map (fun (i, c) -> (i, OptB c)) defs in
        (mods, [])
    | (VarParam :: params_tl, _) ->
      let defs = get_default_params params_tl in
      let mods = map (fun (i, c) -> (i, OptB c)) defs in
        (mods, mems)
    | (Param id :: params_tl, mem :: mems_tl) ->
        let (binds, vars) = match_mems params_tl mems_tl in
          ((id, OptA mem) :: binds, vars)
    | (Default (id, _) :: params_tl, mem :: mems_tl) ->
        let (binds, vars) = match_mems params_tl mems_tl in
          ((id, OptA mem) :: binds, vars)

(* Oh god I really hope this function works, I've spent too much time here *)
let match_lambda_app :
  param list -> (arg * memref) list -> env -> heap ->
    (ident * ((memref, const) either)) list * memref list =
  fun params args env heap ->
    let (regs, nameds) = split_eithers (pull_args args heap) in
    let nameds2 = map (fun (i, m) -> (i, OptA m)) nameds in
    let unuseds = remove_used_params params (map pair_first nameds) in
    let (posits, vards) = match_mems unuseds regs in
      (nameds2 @ posits, vards)


(*
  expr list -> memref -> memref -> heap -> (memref * heap) option =
  fun exprs expr_env_mem inj_env_mem heap ->
    let proms = map (fun e -> PromiseObj (e, expr_env_mem)) exprs in
    let (mems, heap2) = heap_alloc_list proms heap in
    let data = DataObj (RefArray mems, attrs_empty) in
    let (d_mem, heap3) = heap_alloc data heap2 in
      match env_mem_add id_variadic d_mem inj_env_mem heap3 with
        | None -> None
        | Some heap4 -> Some (d_mem, heap4)

let lift_binds :
  (ident * expr) list -> memref -> memref -> heap ->
  ((ident * memref) list * heap) option =
  fun binds expr_env_mem inj_env_mem heap ->
    let pairs1 =
        map (fun (b, e) -> (b, PromiseObj (e, expr_env_mem))) binds in
    let (pairs2, heap2) =
        fold_left (fun (acc, hp) (b, p) ->
                          let (m, hp2) = heap_alloc p hp in
                            ((b, m) :: acc, hp2))
                       ([], heap) pairs1 in
      match env_mem_add_list pairs2 inj_env_mem heap2 with
        | None -> None
        | Some heap3 -> Some (pairs2, heap3)
*)

let is_mem_true : memref -> heap -> bool =
  fun mem heap -> true

let is_mem_val : memref -> heap -> bool =
  fun mem heap ->
    match heap_find mem heap with
    | Some(DataObj _) -> true
    | _-> false

let rec unwind_to_loop_slot :
  stack -> (expr * expr * memref * memref * stack) option =
  fun stack ->
    match stack_pop_v stack with
    | Some (LoopSlot (cond, body, o_body_mem), env_mem, stack2) ->
        let body_mem = (match o_body_mem with
                         | None -> mem_null
                         | Some mem -> mem) in
          Some (cond, body, body_mem, env_mem, stack2)
    | Some (_, _, stack2) -> unwind_to_loop_slot stack2
    | None -> None

let rec pull_all_ids : ident list -> env -> heap -> (memref list) option =
  fun ids env heap ->
    match ids with
    | [] -> Some []
    | (id :: ids_tl) ->
        match (env_find id env heap, pull_all_ids ids_tl env heap) with
          | (Some mem, Some mems_tl) -> Some (mem :: mems_tl)
          | _ -> None


(* Rules *)

(* Identifiers *)
let rule_Ident : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Ident id), c_env_mem, c_stack2) ->
      (match env_mem_find id c_env_mem state.heap with
      | Some mem -> (match heap_find mem state.heap with
        | Some (DataObj _) ->
          let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem } in
            [{ state with
                 stack = stack_push c_frame c_stack2 }]
        | _ -> [])
      | _ -> [])
    | _ -> []

(* MemRef *)
let rule_MemRef : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (MemRef mem), c_env_mem, c_stack2) ->
      (match heap_find mem state.heap with
      | Some (DataObj _) ->
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem } in
          [{ state with
               stack = stack_push c_frame c_stack2 }]
      | _ -> [])
    | _ -> []

(* Const *)
let rule_Const : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Const const), c_env_mem, c_stack2) ->
      let (mem, heap2) = heap_alloc_const const state.heap in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = ReturnSlot mem } in
        [{ state with
             heap = heap2;
             stack = stack_push c_frame c_stack2 }]
    | _ -> []

(* Seq *)
let rule_Seq : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Seq exprs), c_env_mem, c_stack2) ->
      if List.length exprs = 0 then
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem_null; } in
          [{ state with
               stack = stack_push c_frame c_stack2 }]
      else
        let c_frames = List.map (fun e -> { frame_default with
                                              env_mem = c_env_mem;
                                              slot = EvalSlot e }) exprs in
          [{ state with
                    stack = stack_push_list c_frames c_stack2 }]
    | _ -> []

(* LambdaAbs *)
let rule_LambdaAbs : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (LambdaAbs (params, expr)), c_env_mem, c_stack2) ->
      let func = DataObj (FuncVal (params, expr, c_env_mem), attrs_empty) in
      let (mem, heap2) = heap_alloc func state.heap in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = ReturnSlot mem} in
        [{ state with
             heap = heap2;
             stack = stack_push c_frame c_stack2 }]
    | _ -> []

(* LambdaApp *)
let rule_LambdaAppEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (LambdaApp (func, args)), c_env_mem, c_stack2) ->
      let f_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot func } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = LambdaSlot (None, [], None, args) } in
        [{ state with
             stack = stack_push_list [f_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_LambdaAppFuncRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot f_mem, _,
            LambdaSlot (None, [], None, args), c_env_mem,
            c_stack2) ->
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = LambdaSlot (Some f_mem, [], None, args) } in
          [{ state with
               stack = stack_push c_frame c_stack2 }]
    | _ -> []

let rule_LambdaAppArgsEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (LambdaSlot (Some f_mem, da_mems, None, arg :: args_tl),
            c_env_mem, c_stack2) ->
      let a_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot (expr_of_arg arg) } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = LambdaSlot (Some f_mem, da_mems,
                                           Some arg, args_tl) } in
        [{ state with
             stack = stack_push_list [a_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_LambdaAppArgsRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot a_mem, _,
            LambdaSlot (Some f_mem, da_mem, Some arg, args), c_env_mem,
            c_stack2) ->
      let da_mems2 = (arg, a_mem) :: da_mem in
      let c_frame = { frame_default with
                  env_mem = c_env_mem;
                  slot = LambdaSlot (Some f_mem, da_mems2, None, args) } in
        [{ state with
             stack = stack_push c_frame c_stack2 }]

    | _ -> []

let rule_LambdaAppEnter : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (LambdaSlot (Some f_mem, da_mems, None, []),
            c_env_mem, c_stack2) ->
      (match heap_find f_mem state.heap with
      | _ -> [])
    | _ -> []


(* NativeLambdaApp *)
let rule_NativeLambdaApp : state -> state list =
  fun state ->
    []

(* Assign *)
let rule_AssignIdEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Assign (Ident id, expr)), c_env_mem, c_stack2) ->
      let e_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot expr } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = AssignSlot id } in
        [{ state with
             stack = stack_push_list [e_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_AssignStrEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Assign (Const (Str rstr), expr)), c_env_mem, c_stack2) ->
      let id = id_of_rstring rstr in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot (Assign (Ident id, expr)) } in
        [{ state with
             stack = stack_push c_frame c_stack2 }]
                                                           
    | _ -> []

let rule_AssignRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot mem, _,
            AssignSlot id, c_env_mem,
            c_stack2) ->

      (match env_mem_add id mem c_env_mem state.heap with
      | Some heap2 ->
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem } in
          [{ state with
               heap = heap2;
               stack = stack_push c_frame c_stack2 }]
      | _ -> [])
    | _ -> []

(* If *)
let rule_IfEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (If (c_expr, t_expr, f_expr)), c_env_mem, c_stack2) ->
      let t_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot c_expr } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = BranchSlot (t_expr, f_expr) } in
        [{ state with
             stack = stack_push_list [t_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_IfRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot mem, _,
            BranchSlot (t_expr, f_expr), c_env_mem,
            c_stack2) ->
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = if is_mem_true mem state.heap then
                                 EvalSlot t_expr
                               else
                                 EvalSlot f_expr } in
        [{ state with
             stack = stack_push c_frame c_stack2 }]
    | _ -> []

(* While *)
let rule_WhileEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (While (cond, body)), c_env_mem, c_stack2) ->
      let d_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot cond } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = LoopSlot (cond, body, Some mem_null) } in
      [{ state with
           stack = stack_push_list [d_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_WhileCondTrue : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot cond_mem, _,
            LoopSlot (cond, body, Some body_mem), c_env_mem,
            c_stack2) ->
      if is_mem_true cond_mem state.heap then
        let b_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = EvalSlot body } in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = LoopSlot (cond, body, None) } in
          [{ state with
               stack = stack_push_list [b_frame; c_frame] c_stack2 }]
      else
        []
    | _ -> []

let rule_WhileCondFalse : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot cond_mem, _,
            LoopSlot (cond, body, Some body_mem), c_env_mem,
            c_stack2) ->
      if is_mem_true cond_mem state.heap then
        []
      else
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot body_mem } in
          [{ state with
               stack = stack_push c_frame c_stack2 }]
    | _ -> []

let rule_WhileBodyDone : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot body_mem, _,
            LoopSlot (cond, body, None), c_env_mem,
            c_stack2) ->
      let d_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot cond } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = LoopSlot (cond, body, Some body_mem) } in
        [{ state with
             stack = stack_push_list [d_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_Break : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot Break, _, c_stack2) ->
      (match unwind_to_loop_slot c_stack2 with
      | Some (_, _, body_mem, l_env_mem, c_stack3) ->
        let c_frame = { frame_default with
                          env_mem = l_env_mem;
                          slot = ReturnSlot body_mem } in
          [{ state with
               stack = stack_push c_frame c_stack3 }]
      | _ -> [])
    | _ -> []

let rule_Next : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot Next, _, c_stack2) ->
      (match unwind_to_loop_slot c_stack2 with
      | Some (cond, body, body_mem, l_env_mem, c_stack3) ->
        let b_frame = { frame_default with
                          env_mem = l_env_mem;
                          slot = EvalSlot body } in
        let c_frame = { frame_default with
                          env_mem = l_env_mem } in
          [{ state with
               stack = stack_push_list [b_frame; c_frame] c_stack2 }]
      | _ -> [])
    | _ -> []


let rule_Blank : state -> state list =
  fun state -> []

(***********************)


let rule_table : (rule * (state -> state list)) list =
  []

