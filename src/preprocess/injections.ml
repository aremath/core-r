open Syntax
open Support
open Natives

type ident = Support.ident
type expr = Support.expr
type param = Support.param
type arg = Support.arg

let nw_fun_arr_sub : (param list) * expr =
  ([Param (id_of_string "array"); VarParam],
   NativeLambdaApp
     (native_array_sub_id,
      [id_of_string "array"; id_variadic]))

let nw_fun_arr_make : (param list) * expr =
  ([VarParam],
   NativeLambdaApp
    (native_array_make_id,
     [id_variadic]))

let native_injection_pairs : (ident * (param list * expr)) list =
  [ (native_array_sub_id, nw_fun_arr_sub);
    (native_array_make_id, nw_fun_arr_make) ]


