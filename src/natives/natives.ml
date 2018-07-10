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

(* Vector length *)
let native_vector_length_id: ident = native_id_of_string "vector.length"
let nw_fun_vec_length : (param list) * expr =
    ([Param (id_of_string "data")],
    NativeLambdaApp
        (native_vector_length_id,
        [id_of_string "data"]))

(* Vector binary operations *)

(* Sets up a native lambda app for a function with name ident that takes two arguments:
 vector1 and vector2 *)
let vec_binop: ident -> param list * expr =
    fun id ->
    ([Param (id_of_string "vector1"); Param (id_of_string "vector2")],
    NativeLambdaApp
        (id,
        [id_of_string "vector1"; id_of_string "vector2"]))

let native_vector_add_id : ident = native_id_of_string "vector.add"
let nw_fun_vec_add: param list * expr =
    vec_binop (native_vector_add_id)

let native_vector_mul_id = native_id_of_string "vector.mul"
let nw_fun_vec_mul = vec_binop (native_vector_mul_id)

let native_vector_div_id = native_id_of_string "vector.div"
let nw_fun_vec_div: param list * expr = vec_binop (native_vector_div_id)

let native_vector_sub_id = native_id_of_string "vector.sub"
let nw_fun_vec_sub = vec_binop (native_vector_sub_id)

let native_vector_mod_id = native_id_of_string "vector.mod"
let nw_fun_vec_mod = vec_binop (native_vector_mod_id)

let native_vector_exp_id = native_id_of_string "vector.exp"
let nw_fun_vec_exp = vec_binop (native_vector_exp_id)

(* Comparison *)
let native_vector_lt_id = native_id_of_string "vector.lt"
let nw_fun_vec_lt = vec_binop (native_vector_lt_id)

let native_vector_gt_id = native_id_of_string "vector.gt"
let nw_fun_vec_gt = vec_binop (native_vector_gt_id)

let native_vector_eq_id = native_id_of_string "vector.eq"
let nw_fun_vec_eq = vec_binop (native_vector_eq_id)

let native_vector_neq_id = native_id_of_string "vector.neq"
let nw_fun_vec_neq = vec_binop (native_vector_neq_id)

let native_vector_geq_id = native_id_of_string "vector.geq"
let nw_fun_vec_geq = vec_binop (native_vector_geq_id)

let native_vector_leq_id = native_id_of_string "vector.leq"
let nw_fun_vec_leq = vec_binop (native_vector_leq_id)

(* Logic *)
let native_vector_andvec_id = native_id_of_string "vector.andvec"
let nw_fun_vec_andvec = vec_binop (native_vector_andvec_id)

let native_vector_and_id = native_id_of_string "vector.and"
let nw_fun_vec_and = vec_binop (native_vector_and_id)

let native_vector_orvec_id = native_id_of_string "vector.orvec"
let nw_fun_vec_orvec = vec_binop (native_vector_orvec_id)

let native_vector_or_id = native_id_of_string "vector.or"
let nw_fun_vec_or = vec_binop (native_vector_or_id)

let native_vector_xor_id = native_id_of_string "vector.xor"
let nw_fun_vec_xor = vec_binop (native_vector_xor_id)

(* Pairs to inject with *)
let native_injection_pairs : (ident * (param list * expr)) list =
  [
    (native_vector_subscript_id, nw_fun_vec_subscript);
    (native_vector_subset_id, nw_fun_vec_subset);
    (native_vector_make_id, nw_fun_vec_make);
    (native_vector_length_id, nw_fun_vec_length);

    (native_vector_add_id, nw_fun_vec_add);
    (native_vector_mul_id, nw_fun_vec_mul);
    (native_vector_div_id, nw_fun_vec_div);
    (native_vector_sub_id, nw_fun_vec_sub);
    (native_vector_mod_id, nw_fun_vec_mod);
    (native_vector_exp_id, nw_fun_vec_exp);
    (native_vector_lt_id, nw_fun_vec_lt);
    (native_vector_gt_id, nw_fun_vec_gt);
    (native_vector_eq_id, nw_fun_vec_eq);
    (native_vector_neq_id, nw_fun_vec_neq);
    (native_vector_geq_id, nw_fun_vec_geq);
    (native_vector_leq_id, nw_fun_vec_leq);
    (native_vector_andvec_id, nw_fun_vec_andvec);
    (native_vector_and_id, nw_fun_vec_and);
    (native_vector_orvec_id, nw_fun_vec_orvec);
    (native_vector_or_id, nw_fun_vec_or);
    (native_vector_xor_id, nw_fun_vec_xor)
  ]

