open Syntax
open Support


let native_rstring : rstring =
  rstring_of_string "$native"

let native_id_of_rstring : rstring -> ident =
  fun name -> { (id_of_rstring name) with pkg = Some native_rstring }

let native_id_of_string : string -> ident =
  fun name ->
    native_id_of_rstring (rstring_of_string name)


let native_array_sub_id: ident = native_id_of_string "array.sub"

let native_array_make_id : ident = native_id_of_string "array.make"

