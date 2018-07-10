
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
let do_rvector_bop: (rvector -> rvector -> rvector) -> memref list -> memref -> state -> state option =
    fun op arg_mems c_env_mem state ->
    match arg_mems with
    | (v1 :: v2 :: []) ->
        let (mem2, heap2) = vector_bop_mems op v1 v2 state.heap in
        let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
        Some { state with
                    heap = heap2;
                    stack = stack_push c_frame state.stack }
    | _ -> None

let native_call : ident -> memref list -> memref -> state -> state option =
  fun id arg_mems c_env_mem state ->
    (* Vector subscripting *)
    if id = native_vector_subscript_id then
      (match arg_mems with
      | (vec_mem :: sub_mem :: []) ->
        let (mem2, heap2) = subscript_mems vec_mem sub_mem state.heap in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state with
                   heap = heap2;
                   stack = stack_push c_frame state.stack }
      | _ -> None)

    (* Vector subsetting *)
    else if id = native_vector_subset_id then
      (match arg_mems with
      | (vec_mem :: var_mem :: []) ->
        (match heap_find var_mem state.heap with
        | Some (DataObj (RefArray refs, _)) ->
          let (mem2, heap2) = subset_mems vec_mem refs state.heap in
          let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
            Some { state with
                     heap = heap2;
                     stack = stack_push c_frame state.stack }
        | _ -> None)
      | _ -> None)

    (* Vector creation *)
    else if id = native_vector_make_id then
      (match arg_mems with
      | (var_mem :: []) ->
          (match heap_find var_mem state.heap with
          | Some (DataObj (RefArray refs, _)) ->
            let (mem2, heap2) = make_vector_simple_mems refs state.heap in
            let c_frame = { frame_default with
                              env_mem = c_env_mem;
                              slot = ReturnSlot mem2 } in
              Some { state with
                       heap = heap2;
                       stack = stack_push c_frame state.stack }
          | _ -> None)
      | _ -> None)

    (* Vector length *)
    else if id = native_vector_length_id then
      (match arg_mems with
      | (data_mem :: []) ->
        let (mem2, heap2) = rvec_length_mem data_mem state.heap in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state with
                   heap = heap2;
                   stack = stack_push c_frame state.stack }
      | _ -> None)

    else if id = native_vector_colon_id then
      (match arg_mems with
      | (low_mem :: high_mem :: []) ->
        let (mem2, heap2) = range_int_mems low_mem high_mem state.heap in
        let c_frame = { frame_default with
                          env_mem = c_env_mem;
                          slot = ReturnSlot mem2 } in
          Some { state with
                   heap = heap2;
                   stack = stack_push c_frame state.stack }
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

    (* Oh no! *)
    else
      None

