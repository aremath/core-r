
open Syntax
open Support
open Subscript
module U = Langutils
open Natives
open Vector
open Arithmetic

open List

type ident = Support.ident

let binop_names : string list =
  ["+"; "-"; "*"; "/"; "^";
   "%%"; "%/%"; "%*%"; "%*%"; "%x"; "%in%";
   ">"; ">="; "<"; "<="; "=="; "!=";
   "&&"; "&"; "||"; "|"; "~";
   "<-"; "<<-"; "@"; ":"; "?"; "::"; ":::";
   ]

let extract_native_name : ident -> string option =
  fun id -> 
    match id.pkg with
    | None -> None
    | Some pkg ->
      if pkg = native_rstring then
        string_of_rstring id.name
      else
        None

(* Basic form for every binary operation: 
 expect two arguments only, and put the result in a ReturnSlot.
 The only difference here is which op to do (possible ops in arithmetic.ml) *)
(* TODO: a little ugly to need to pass the env_mem and the state... *)
let do_rvector_bop: (rvector -> rvector -> state -> rvector * state) -> 
        memref list -> memref -> state -> state option =
    fun op arg_mems c_env_mem state ->
    match arg_mems with
    | (v1 :: v2 :: []) ->
        let (mem2, state2) = vector_bop_mems op v1 v2 state in
        let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
        Some { state2 with stack = stack_push c_frame state.stack }
    | _ -> None

(* Matches the identifier used for the call to determine which native mems call it needs to perform
  and matches the memory addresses passed in to the arguments expected. Called when the evaluator sees
  a NativeLambdaApp. Fails when it can't recognize the identifier for the NativeLambdaApp - the function
  requested either doesn't exist or hasn't been registered (see interpreter/interp-commons/natives.ml),
  or when a different number of arguments are passed from expected. Notably does not dereference
  the arguments. *)
let native_call : ident -> memref list -> memref -> state -> state option =
  fun id arg_mems c_env_mem state ->
    (* Vector subscripting *)
    if id = native_vector_subscript_id then
      (match arg_mems with
      | (vec_mem :: sub_mem :: []) ->
        let (mem2, state2) = subscript_mems vec_mem sub_mem state in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state2 with stack = stack_push c_frame state.stack }
      | _ -> None)

    (* Vector subsetting *)
    else if id = native_vector_subset_id then
      (match arg_mems with
      | (vec_mem :: var_mem :: []) ->
        (match heap_find var_mem state.heap with
        | Some (DataObj (RefArray refs, _)) ->
          let (mem2, state2) = subset_mems vec_mem refs state in
          let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
            Some { state2 with stack = stack_push c_frame state.stack }
        | _ -> None)
      | _ -> None)

    (* Vector creation *)
    else if id = native_vector_make_id then
      (match arg_mems with
      | (var_mem :: []) ->
          (match heap_find var_mem state.heap with
          | Some (DataObj (RefArray refs, _)) ->
            let (mem2, state2) = make_vector_mems var_mem state in
            let c_frame = { frame_default with
                              env_mem = c_env_mem;
                              slot = ReturnSlot mem2 } in
              Some { state2 with stack = stack_push c_frame state.stack }
          | _ -> None)
      | _ -> None)

    (* Vector length *)
    else if id = native_vector_length_id then
      (match arg_mems with
      | (data_mem :: []) ->
        let (mem2, state2) = rvector_length_mem data_mem state in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state2 with stack = stack_push c_frame state.stack }
      | _ -> None)

    else if id = native_vector_colon_id then
      (match arg_mems with
      | (low_mem :: high_mem :: []) ->
        let (mem2, state2) = range_mems low_mem high_mem state in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state2 with stack = stack_push c_frame state.stack }
      | _ -> None)

    (* Vector binary operations *)
    else if id = native_vector_add_id then
       do_rvector_bop rvector_add arg_mems c_env_mem state
    else if id = native_vector_mul_id then
        do_rvector_bop rvector_mul arg_mems c_env_mem state
    else if id = native_vector_div_id then
        do_rvector_bop rvector_div arg_mems c_env_mem state
    else if id = native_vector_sub_id then
        do_rvector_bop rvector_sub arg_mems c_env_mem state
    else if id = native_vector_mod_id then
        do_rvector_bop rvector_mod arg_mems c_env_mem state
    else if id = native_vector_exp_id then
        do_rvector_bop rvector_exp arg_mems c_env_mem state
    else if id = native_vector_lt_id then
        do_rvector_bop rvector_lt arg_mems c_env_mem state
    else if id = native_vector_gt_id then
        do_rvector_bop rvector_gt arg_mems c_env_mem state
    else if id = native_vector_eq_id then
        do_rvector_bop rvector_eq arg_mems c_env_mem state
    else if id = native_vector_neq_id then
        do_rvector_bop rvector_neq arg_mems c_env_mem state
    else if id = native_vector_geq_id then
        do_rvector_bop rvector_geq arg_mems c_env_mem state
    else if id = native_vector_leq_id then
        do_rvector_bop rvector_leq arg_mems c_env_mem state
    else if id = native_vector_andvec_id then
        do_rvector_bop rvector_andvec arg_mems c_env_mem state
    else if id = native_vector_and_id then
        do_rvector_bop rvector_and arg_mems c_env_mem state
    else if id = native_vector_orvec_id then
        do_rvector_bop rvector_orvec arg_mems c_env_mem state
    else if id = native_vector_or_id then
        do_rvector_bop rvector_or arg_mems c_env_mem state
    else if id = native_vector_xor_id then
        do_rvector_bop rvector_xor arg_mems c_env_mem state

    else if id = native_vector_symbolic_id then
      (match arg_mems with
      | (len_mem :: type_mem :: []) ->
        let (mem2, state2) =  make_symbolic_mems len_mem type_mem state in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state2 with stack = stack_push c_frame state.stack }
      | _ -> None)
        
    (* Oh no! *)
    else
      None

