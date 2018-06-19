
let is_native : ident -> state -> bool =
  fun ident state -> false

let native_call : ident -> memref list > env -> state -> option state =
  fun id args env state -> None


