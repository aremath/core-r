
open List
open Syntax
open Support
open Native_calls
open Copy
open Langutils

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

let rec default_params_val_pairs : param list -> ((ident * const) list) option =
  fun params ->
    match params with
    | [] -> Some []
    | (Param _ :: params_tl) -> default_params_val_pairs params_tl
    | (VarParam :: params_tl) -> default_params_val_pairs params_tl
    (* We only permit const values for now, that's why we have option here *)
    | ((Default (id, Const const)) :: params_tl) ->
        (match default_params_val_pairs params_tl with
        | Some tl -> Some ((id, const) :: tl)
        | _ -> None)
    | ((Default _) :: params_tl) -> None

(*
  args - the argument / memref pairs we pull.
         We track the arg for variadics, and named parameters.
         We never actually really use the contents inside besides the Named id.
  heap - The heap we are drawing from.

  If successful, returns a list where each element is the corresponding
  memref (OptA) or the (id, memref) (OptB) if it was named.
*)
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
        (* We need to have variadic arguments to match with their names *)
        (match heap_find mem heap with
        | Some (DataObj (RefArray v_mems, attrs)) ->
          (match pull_args args_tl heap with
          | Some tl ->
            (match attrs_find (rstring_of_string "names") attrs with
            | Some names_mem ->
              (match heap_find names_mem heap with
              | Some (DataObj (Vec (StrVec rstrs), _)) ->
                if Array.length rstrs = length v_mems then
                  let pairs = combine (Array.to_list rstrs) v_mems in
                  let v_args =
                      map (fun (a, m) ->
                        if (a = na_rstring) || (a = rstring_of_string "") then
                          OptA m
                        else
                          OptB (id_of_rstring a, m)) pairs in
                    Some (v_args @ tl)
                else
                  None
              | _ -> None)
            | _ -> Some ((map (fun m -> OptA m) v_mems) @ tl))
          | _ -> None)
        | _ -> None)


(*
  params - The parameters we are filtering out.
  id - the id we are filtering by
*)
let filter_used_param : param list -> ident -> param list =
  fun params id ->
    filter (fun p -> match p with
                     | Param p_id -> id.name <> p_id.name
                     | Default (p_id, _) -> id.name <> p_id.name
                     | VarParam -> true)
           params

(*
  at this point, the arguments are going to be memory references on
  the heap since they have already been evaluated due to assuemd eagerness
*)
let default_match_fold_fun :
    (param list *
        ((memref, (ident * memref)) either) list *
        (ident * memref) list) ->
    ((memref, (ident * memref)) either) ->
    (param list *
        ((memref, (ident * memref)) either) list *
        (ident * memref) list) =
  fun (params_remaining, unmatched_args, matched_args) arg ->
    match arg with
    | OptA mem ->
        (params_remaining, unmatched_args @ [arg], matched_args)
    | OptB (id, mem) ->
        let filtered = filter_used_param params_remaining id in
          (* Match successful if we have less after filtering *)
          if length filtered < length params_remaining then
            (filtered, unmatched_args, matched_args @ [(id, mem)])
          (* Match unsuccessful if it did not accomplish anything *)
          else
            (filtered, unmatched_args @ [arg], matched_args)

(*
  match the remaining parameters and also detect the variadic match
  we output (the matched positional argument, variadic argument with naming)
*)
let rec positional_match :
  param list ->
  ((memref, (ident * memref)) either) list ->
      ((ident * ((memref, const) either)) list *
       ((memref, (ident * memref)) either) list) option =
  fun params args ->
    match (params, args) with
    (* Have more args than params available, disregard excessive args *)
    | ([], _) -> Some ([], [])
    (* Have not enough params remaining *)
    | (_, []) ->
      (match default_params_val_pairs params with
      | Some defaults ->
        let mods = map (fun (i, c) -> (i, OptB c)) defaults in
          Some (mods, [])
      | _ -> None)
    (* After hitting a variadic parameter, the best we can do is get the
       tail of the default values and move on *)
    | (VarParam :: params_tl, _) ->
      (match default_params_val_pairs params_tl with
      | Some defaults ->
          let mods = map (fun (i, c) -> (i, OptB c)) defaults in
            Some (mods, args)
      | _ -> None)
    (* When we hit a regular parameter, we can only expect to match to
       non-named arguments, because all those relevant should have been
       filtered out earlier. If not, they would have matched with variadics *)
    | (Param p_id :: params_tl, arg :: args_tl) ->
        (match arg with
        (* If the argument here is a named one, then it should have been
           filtered out earlier if it was going to be used. Discard it *)
        | OptB (_, _) -> positional_match params args_tl
        (* If the argument is just regular memory, then we are fine *)
        | OptA a_mem ->
          (match positional_match params_tl args_tl with
          | Some (binds, vars) -> Some ((p_id, OptA a_mem) :: binds, vars)
          | _ -> None))
    (* The default parameter value is overwritten by the argument *)
    | (Default (p_id, _) :: params_tl, arg :: args_tl) ->
      (match arg with
      (* Like with the regular parameters, we drop named arguments *)
      | OptB (_, _) -> positional_match params args_tl
      | OptA a_mem ->
        (match positional_match params_tl args_tl with
        | Some (binds, vars) -> Some ((p_id, OptA a_mem) :: binds, vars)
        | _ -> None))



(********************************)
(* Prune a list of used parameters *)
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
      (match default_params_val_pairs params with
      | Some defs ->
        let mods = map (fun (i, c) -> (i, OptB c)) defs in
          Some (mods, [])
      | _ -> None)
    | (VarParam :: params_tl, _) ->
      (match default_params_val_pairs params_tl with
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
    ((ident * ((memref, const) either)) list *
     ((memref, (ident * memref)) either) list) option =
  fun params arg_mems env heap ->
    match pull_args arg_mems heap with
    | Some pulled ->
      let (rem_params, rem_args, used_args) =
          fold_left default_match_fold_fun (params, [], []) pulled in

        (match positional_match rem_params rem_args with
        | Some (matched, vars) ->
            let mods = map (fun (i, m) -> (i, OptA m)) used_args in
            Some (mods @ matched, vars)
        | _ -> None)
    | _ -> None


(*
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
      | Some (posits, vards) ->
          Some (nameds2 @ posits, vards)
      | _ -> None)
    | _ -> None
  *)

let lift_variadic_binds :
  ((memref, (ident * memref)) either) list -> memref -> heap ->
    (memref * heap) option =
  fun args env_mem heap ->
    let mems = map (fun a -> match a with
                      | OptA a_mem -> a_mem
                      | OptB (_, a_mem) -> a_mem) args in
    begin
    let names_vec =
          StrVec (Array.of_list
                    (map (fun a -> match a with
                       | OptA _ -> rstring_of_string ""
                       | OptB (p_id, _) -> p_id.name) args)) in
    let (s_mem, heap2) = heap_alloc (DataObj (Vec names_vec, attrs_empty ()))
                                    heap in
    let ref_attr = attrs_empty () in
    let _ = attrs_add (rstring_of_string "names") s_mem ref_attr in
    let refs = DataObj (RefArray mems, ref_attr) in
    let (ref_mem, heap3) = heap_alloc refs heap2 in
      match env_mem_add id_variadic ref_mem env_mem heap3 with
        | Some heap4 -> Some (ref_mem, heap4)
        | _ -> None
    end
(*
let lift_variadic_binds : memref list -> memref -> heap ->
  (memref * heap) option =
  fun mems env_mem heap ->
    let refs = DataObj ((RefArray mems), attrs_empty) in
    let (mem, heap2) = heap_alloc refs heap in
      match env_mem_add id_variadic mem env_mem heap2 with
      | Some heap3 -> Some (mem, heap3)
      | _ -> None
*)

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
  fun mem heap ->
    match heap_find mem heap with
    | Some (DataObj (Vec rvec, _)) ->
      (match (rvector_get_rint rvec 1,
              rvector_get_rfloat rvec 1,
              rvector_get_rcomplex rvec 1,
              rvector_get_rstring rvec 1,
              rvector_get_rbool rvec 1) with
      | (Some v, _, _, _, _) -> v <> rint_of_int 0
      | (_, Some v, _, _, _) -> v <> rfloat_of_float 0.0
      | (_, _, Some v, _, _) -> v <> rcomplex_of_complex Complex.zero
      | (_, _, _, Some v, _) -> true
      | (_, _, _, _, Some v) -> v <> rbool_of_bool 0
      | _ -> false)
    | _ -> true
    | None -> false

let rec unwind_to_loop_slot :
  stack -> ((expr * expr * memref) * memref * stack) option =
  fun stack ->
    match stack_pop_v stack with
    | Some (LoopSlot (cond, body, o_body_mem), env_mem, stack2) ->
        let body_mem = (match o_body_mem with
                         | None -> mem_null
                         | Some mem -> mem) in
          Some ((cond, body, body_mem), env_mem, stack2)
    | Some (_, _, stack2) -> unwind_to_loop_slot stack2
    | None -> None

let rec unwind_to_lambdab_slot :
  stack -> (memref * memref * stack) option =
  fun stack ->
    match stack_pop_v stack with
    | Some (LambdaBSlot mem, env_mem, stack2) ->
        Some (mem, env_mem, stack2)
    | Some (_, _, stack2) -> unwind_to_lambdab_slot stack2
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
      let f_env = { env_empty with pred_mem = c_env_mem } in
      let f_env_obj = DataObj (EnvVal f_env, attrs_empty ()) in
      let (f_env_mem, heap2) = heap_alloc f_env_obj state.heap in
      let func = DataObj (FuncVal (params, expr, f_env_mem), attrs_empty ()) in
      let (mem, heap2) = heap_alloc func heap2 in
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
                        slot = LambdaASlot (None, [], None, args) } in
        [{ state with
             stack = stack_push_list [f_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_LambdaAppFuncRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot f_mem, _,
            LambdaASlot (None, [], None, args), c_env_mem,
            c_stack2) ->
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = LambdaASlot (Some f_mem, [], None, args) } in
          [{ state with
               stack = stack_push c_frame c_stack2 }]
    | _ -> []

let rule_LambdaAppArgsEval : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (LambdaASlot (Some f_mem, da_mems, None, arg :: args_tl),
            c_env_mem, c_stack2) ->
      let a_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = EvalSlot (expr_of_arg arg) } in
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = LambdaASlot (Some f_mem, da_mems,
                                           Some arg, args_tl) } in
        [{ state with
             stack = stack_push_list [a_frame; c_frame] c_stack2 }]
    | _ -> []

let rule_LambdaAppArgsRet : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot a_mem, _,
            LambdaASlot (Some f_mem, da_mem, Some arg, args), c_env_mem,
            c_stack2) ->
      let da_mems2 = da_mem @ [(arg, a_mem)] in
      let c_frame = { frame_default with
                  env_mem = c_env_mem;
                  slot = LambdaASlot (Some f_mem, da_mems2, None, args) } in
        [{ state with
             stack = stack_push c_frame c_stack2 }]

    | _ -> []

let rule_LambdaAppEnter : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (LambdaASlot (Some f_mem, da_mems, None, []),
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
                let e_frame = { frame_default with
                                  env_mem = f_env_mem;
                                  slot = EvalSlot body } in
                let c_frame = { frame_default with
                                  env_mem = c_env_mem;
                                  slot = LambdaBSlot f_mem } in
                  [{ state with
                       heap = heap3;
                       stack = stack_push_list [e_frame; c_frame] c_stack2 }]
              | _ -> [])
            | _ -> [])
          | _ -> [])
        | _ -> [])
      | _ -> [])
    | _ -> []

let rule_LambdaAppComplete : state -> state list =
  fun state ->
    match stack_pop_v2 state.stack with
    | Some (ReturnSlot mem, _,
            LambdaBSlot _, c_env_mem, c_stack2) ->
      let c_frame = { frame_default with
                        env_mem = c_env_mem;
                        slot = ReturnSlot mem } in
        [{ state with
             stack = stack_push c_frame c_stack2 }]
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
      | Some ((_, _, body_mem), l_env_mem, c_stack3) ->
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
      | Some ((cond, body, body_mem), l_env_mem, c_stack3) ->
        let b_frame = { frame_default with
                          env_mem = l_env_mem;
                          slot = EvalSlot body } in
        let c_frame = { frame_default with
                          env_mem = l_env_mem;
                          slot = LoopSlot (cond, body, Some body_mem) } in
          [{ state with
               stack = stack_push_list [b_frame; c_frame] c_stack3 }]
      | _ -> [])
    | _ -> []


let rule_Return : state -> state list =
  fun state ->
    match stack_pop_v state.stack with
    | Some (EvalSlot (Return expr), c_env_mem, c_stack2) ->
      (match unwind_to_lambdab_slot c_stack2 with
      | Some (f_mem, l_env_mem, c_stack3) ->
        let r_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = EvalSlot expr } in
        let c_frame = { frame_default with
                          env_mem = l_env_mem;
                          slot = LambdaBSlot f_mem } in
          [{ state with
               stack = stack_push_list [r_frame; c_frame] c_stack3 }]
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
  | ERuleLambdaAppComplete
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
  | ERuleReturn
  | ERuleDiscard
  | ERuleBlank


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
    (ERuleLambdaAppComplete, rule_LambdaAppComplete);
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
    (ERuleReturn, rule_Return);
    (ERuleDiscard, rule_Discard);
    (ERuleBlank, rule_Blank) ]


