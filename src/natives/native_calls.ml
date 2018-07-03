
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

    (* Vector binary operations *)
    else if id = native_vector_add_id then
      (match arg_mems with
      | (v1 :: v2 :: []) ->
          let (mem2, heap2) = vector_bop_mems rvector_add v1 v2 state.heap in
          let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
            Some { state with
                     heap = heap2;
                     stack = stack_push c_frame state.stack }
      | _ -> None)

    else if id = native_vector_mul_id then
      (match arg_mems with
      | (v1 :: v2 :: []) ->
          let (mem2, heap2) = vector_bop_mems rvector_mul v1 v2 state.heap in
          let c_frame = { frame_default with
                            env_mem = c_env_mem;
                            slot = ReturnSlot mem2 } in
            Some { state with
                     heap = heap2;
                     stack = stack_push c_frame state.stack }
      | _ -> None)
    (* Oh no! *)
    else
      None



