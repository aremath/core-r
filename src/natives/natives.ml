open Syntax
open Support

let native_rstring : rstring =
  rstring_of_string "$native"

let native_id_of_rstring : rstring -> ident =
  fun name -> { (id_of_rstring name) with pkg = Some native_rstring }

let native_id_of_string : string -> ident =
  fun name ->
    native_id_of_rstring (rstring_of_string name)


(* Vector subsetting *)
let native_vector_subscript_id: ident = native_id_of_string "vector.subscript"

let nw_fun_vec_subscript : (param list) * expr =
  ([Param (id_of_string "vector"); Param (id_of_string "sub")],
   NativeLambdaApp
     (native_vector_subscript_id,
      [id_of_string "vector"; id_of_string "sub"]))

let native_vector_subset_id : ident = native_id_of_string "vector.subset"

let nw_fun_vec_subset : (param list) * expr =
  ([Param (id_of_string "vector"); VarParam],
   NativeLambdaApp
     (native_vector_subset_id,
      [id_of_string "vector"; id_variadic]))

(* Vector making *)
let native_vector_make_id : ident = native_id_of_string "vector.make"

let nw_fun_vec_make : (param list) * expr =
  ([VarParam],
   NativeLambdaApp
    (native_vector_make_id,
     [id_variadic]))

(* Vector binary operations *)
let native_vector_add_id : ident = native_id_of_string "vector.add"

let nw_fun_vec_add : (param list) * expr =
  ([Param (id_of_string "vector1"); Param (id_of_string "vector2")],
   NativeLambdaApp
     (native_vector_add_id,
      [id_of_string "vector1"; id_of_string "vector2"]))

let native_vector_mult_id: ident = native_id_of_string "vector.mult"

let nw_fun_vec_mult : (param list) * expr =
  ([Param (id_of_string "vector1"); Param (id_of_string "vector2")],
   NativeLambdaApp
     (native_vector_mult_id,
      [id_of_string "vector1"; id_of_string "vector2"]))


(* Pairs to inject with *)
let native_injection_pairs : (ident * (param list * expr)) list =
  [
    (native_vector_subscript_id, nw_fun_vec_subscript);
    (native_vector_subset_id, nw_fun_vec_subset);
    (native_vector_make_id, nw_fun_vec_make);
    (native_vector_add_id, nw_fun_vec_add);
    (native_vector_mult_id, nw_fun_vec_mult);
  ]

