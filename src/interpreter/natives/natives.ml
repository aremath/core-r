
open Support
open Subscript

open List

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
      match string_of_rstring pkg with
      | None -> None
      | Some "$native" -> string_of_rstring id.name
      | Some _ -> None

let native_call : ident -> memref list -> memref -> state -> state option =
  fun id arg_mems c_env_mem state ->
    match extract_native_name id with
    | None -> None
    | Some name ->
      match name with
      | "$native_array_sub" ->
        (match arg_mems with
        | (arr_mem :: var_mem :: []) ->
          (match heap_find var_mem state.heap with
          | Some (DataObj (RefArray refs, _)) ->
              let (mem2, heap2) = subset_mems arr_mem refs state.heap in
              let c_frame = { frame_default with
                                env_mem = c_env_mem;
                                slot = ReturnSlot mem2 } in
                Some { state with
                         heap = heap2;
                         stack = stack_push c_frame state.stack }
          | _ -> None)
        | _ -> None)
      | _ -> None



