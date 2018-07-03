
open List
open Syntax
open Support
open Native_calls
open Copy

type rule =
  | ERuleIdent
  | ERuleMemRef
  | ERuleConst
  | ERuleSeq
  | ERuleLambdaAbs
  | ERuleLambdaAppEval
  | ERuleLambdaAppFuncRet
  | ERuleLambdaAppArgsEval
  | ERuleLambdaAppArgsRet
  | ERuleLambdaAppEnter
  | ERuleNativeLambdaApp
  | ERuleAssignIdEval
  | ERuleAssignStrEval
  | ERuleAssignRet
  | ERuleIfEval
  | ERuleIfRet
  | ERuleWhileEval
  | ERuleWhileCondTrue
  | ERuleWhileCondFalse
  | ERuleWhileBodyDone
  | ERuleBreak
  | ERuleNext
  | ERuleDiscard
  | ERuleBlank


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

let rec get_default_params : param list -> ((ident * const) list) option =
  fun params ->
    match params with
    | [] -> Some []
    | (Param _ :: params_tl) -> get_default_params params_tl
    | (VarParam :: params_tl) -> get_default_params params_tl
    | ((Default (id, Const const)) :: params_tl) ->
        (match get_default_params params_tl with
        | Some tl -> Some ((id, const) :: tl)
        | _ -> None)
    | ((Default _) :: params_tl) -> None

let rec pull_args :
  (arg * memref) list -> heap ->
    (((memref, (ident * memref)) either) list) option =
  fun args heap ->
    match args with
    | [] -> Some []
    | ((Arg _, mem) :: args_tl) ->
      (match pull_args args_tl heap with
      | Some tl -> Some (OptA mem :: tl)
      | _ -> None)
    | ((Named (id, _), mem) :: args_tl) ->
      (match pull_args args_tl heap with
      | Some tl -> Some (OptB (id, mem) :: tl)
      | _ -> None)
    | ((VarArg, mem) :: args_tl) ->
        (match heap_find mem heap with
        | Some (DataObj (RefArray v_mems, _)) ->
          (match pull_args args_tl heap with
          | Some tl -> Some ((map (fun m -> OptA m) v_mems) @ tl)
          | _ -> None)
        | _ -> None)
          
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
    ((ident * ((memref, const) either)) list * (memref list)) option =
  fun params mems ->
    match (params, mems) with
    | ([], _) -> Some ([], []) (* OH NO??? *)
    | (_, []) ->
      (match get_default_params params with
      | Some defs ->
        let mods = map (fun (i, c) -> (i, OptB c)) defs in
          Some (mods, [])
      | _ -> None)
    | (VarParam :: params_tl, _) ->
      (match get_default_params params_tl with
      | Some defs ->
        let mods = map (fun (i, c) -> (i, OptB c)) defs in
          Some (mods, mems)
      | _ -> None)
    | (Param id :: params_tl, mem :: mems_tl) ->
      (match match_mems params_tl mems_tl with
      | Some (binds, vars) -> Some ((id, OptA mem) :: binds, vars)
      | _ -> None)
    | (Default (id, _) :: params_tl, mem :: mems_tl) ->
      (match match_mems params_tl mems_tl with
      | Some (binds, vars) -> Some ((id, OptA mem) :: binds, vars)
      | _ -> None)

(* Oh god I really hope this function works, I've spent too much time here *)
let match_lambda_app :
  param list -> (arg * memref) list -> env -> heap ->
    ((ident * ((memref, const) either)) list * memref list) option =
  fun params args env heap ->
    match pull_args args heap with
    | Some pulled ->
      let (regs, nameds) = split_eithers pulled in
      let nameds2 = map (fun (i, m) -> (i, OptA m)) nameds in
      let unuseds = remove_used_params params (map pair_first nameds) in
      (match match_mems unuseds regs with
      | Some (posits, vards) -> Some (nameds2 @ posits, vards)
      | _ -> None)
    | _ -> None

let lift_variadic_binds : memref list -> memref -> heap ->
  (memref * heap) option =
  fun mems env_mem heap ->
    let refs = DataObj ((RefArray mems), attrs_empty) in
    let (mem, heap2) = heap_alloc refs heap in
      match env_mem_add id_variadic mem env_mem heap2 with
      | Some heap3 -> Some (mem, heap3)
      | _ -> None

let lift_param_binds :
  (ident * ((memref, const) either)) list -> memref -> heap ->
    ((ident * memref) list * heap) option =
  fun binds env_mem heap ->
    let (binds2, heap2) =
          fold_left (fun (bs, h) (b, r) -> match r with
                      | OptA mem -> (bs @ [(b, mem)], h)
                      | OptB c -> let (a_mem, h2) = heap_alloc_const c h in
                                    (bs @ [(b, a_mem)], h2))
                  ([], heap) binds in
      match env_mem_add_list binds2 env_mem heap2 with
      | Some heap3 -> Some (binds2, heap3)
      | _ -> None

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
      let da_mems2 = da_mem @ [(arg, a_mem)] in
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
      (match heap_find c_env_mem state.heap with
      | Some (DataObj (EnvVal env, _)) ->
        (match heap_find f_mem state.heap with
        | Some (DataObj (FuncVal (params, body, f_env_mem), attrs)) ->
          (match match_lambda_app params da_mems env state.heap with
          | Some (binds, vares) ->
            (match lift_variadic_binds vares f_env_mem state.heap with
            | Some (_, heap2) ->
              (match lift_param_binds binds f_env_mem heap2 with
              | Some (_, heap3) ->
                let c_frame = { frame_default with
                                  env_mem = f_env_mem;
                                  slot = EvalSlot body } in
                  [{ state with
                       heap = heap3;
                       stack = stack_push c_frame c_stack2 }]
              | _ -> [])
            | _ -> [])
          | _ -> [])
        | _ -> [])
      | _ -> [])
    | _ -> []


(* NativeLambdaApp *)
let rule_NativeLambdaApp : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (NativeLambdaApp (f_id, arg_ids)), c_env_mem, c_stack2) ->
      (match heap_find c_env_mem state.heap with
      | Some (DataObj (EnvVal env, _)) ->
        (match pull_all_ids arg_ids env state.heap with
        | Some mems ->
          let state2 = { state with stack = c_stack2 } in
          (match native_call f_id mems c_env_mem state2 with
          | Some state3 -> [state3]
          | _ -> [])
        | _ -> [])
      | _ -> [])
    | _ -> []

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

let rule_Discard : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (ReturnSlot _, _, c_stack2) ->
      let pop_okay = match stack_pop_v c_stack2 with
                     | Some (EvalSlot _, _ , _) -> true
                     | Some (ReturnSlot _, _, _) -> true
                     | Some (SeqSlot _, _, _) -> true
                     | _ -> false in
        if pop_okay then
          [{ state with stack = c_stack2 }]
        else
          []
    | _ -> []



let rule_Blank : state -> state list =
  fun state -> []

(***********************)


let rule_table : (rule * (state -> state list)) list =
  [ (ERuleIdent, rule_Ident);
    (ERuleMemRef, rule_MemRef);
    (ERuleConst, rule_Const);
    (ERuleSeq, rule_Seq);
    (ERuleLambdaAbs, rule_LambdaAbs);
    (ERuleLambdaAppEval, rule_LambdaAppEval);
    (ERuleLambdaAppFuncRet, rule_LambdaAppFuncRet);
    (ERuleLambdaAppArgsEval, rule_LambdaAppArgsEval);
    (ERuleLambdaAppArgsRet, rule_LambdaAppArgsRet);
    (ERuleLambdaAppEnter, rule_LambdaAppEnter);
    (ERuleNativeLambdaApp, rule_NativeLambdaApp);
    (ERuleAssignIdEval, rule_AssignIdEval);
    (ERuleAssignStrEval, rule_AssignStrEval);
    (ERuleAssignRet, rule_AssignRet);
    (ERuleIfEval, rule_IfEval);
    (ERuleIfRet, rule_IfRet);
    (ERuleWhileEval, rule_WhileEval);
    (ERuleWhileCondTrue, rule_WhileCondTrue);
    (ERuleWhileCondFalse, rule_WhileCondFalse);
    (ERuleWhileBodyDone, rule_WhileBodyDone);
    (ERuleBreak, rule_Break);
    (ERuleNext, rule_Next);
    (ERuleDiscard, rule_Discard);
    (ERuleBlank, rule_Blank) ]


