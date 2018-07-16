
open Support
open Smtsyntax

let smtvar_of_memref : memref -> smtvar =
  fun mem ->
    smtvar_of_string ("mem$" ^ string_of_int mem.addr)

let smtexpr_of_langexpr : expr -> state -> smtexpr =
  fun expr state -> match expr with
    | _ -> SmtVar "boo"
  
