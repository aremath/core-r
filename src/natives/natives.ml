open Syntax
open Support

let native_rstring : rstring =
  rstring_of_string "$native"

let native_id_of_rstring : rstring -> ident =
  fun name -> { (id_of_rstring name) with pkg = Some native_rstring }

let native_id_of_string : string -> ident =
  fun name ->
    native_id_of_rstring (rstring_of_string name)


(* Array subsetting *)
let native_array_sub_id: ident = native_id_of_string "array.sub"

let nw_fun_arr_sub : (param list) * expr =
  ([Param (id_of_string "array"); Param (id_of_string "sub")],
   NativeLambdaApp
     (native_array_sub_id,
      [id_of_string "array"; id_of_string "sub"]))

(* Array making *)
let native_array_make_id : ident = native_id_of_string "array.make"

let nw_fun_arr_make : (param list) * expr =
  ([VarParam],
   NativeLambdaApp
    (native_array_make_id,
     [id_variadic]))

let native_injection_pairs : (ident * (param list * expr)) list =
  [ (native_array_sub_id, nw_fun_arr_sub);
    (native_array_make_id, nw_fun_arr_make) ]

