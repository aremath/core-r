
open Support

let is_native : ident -> state -> bool =
  fun ident state -> false

let native_call : ident -> memref list -> env -> state -> state option =
  fun id args env state -> None



