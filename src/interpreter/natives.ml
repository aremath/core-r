
let is_native : ident -> state -> bool =
  fun ident state -> false

let native_call : ident -> memref -> state -> option state =
  fun id args state -> None

