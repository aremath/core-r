
open Support

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

let native_call : ident -> memref list -> env -> state -> state option =
  fun id mems env state ->
    match extract_native_name id with
    | None -> None
    | Some name ->
      match name with
      | "$native_array_sub" ->
        (match mems with
        | (arr :: var :: []) ->
          (match heap_find var state.heap with
          | Some (DataObj (RefArray refs, _)) ->
            None
          | _ -> None)
        | _ -> None)
      | _ -> None



