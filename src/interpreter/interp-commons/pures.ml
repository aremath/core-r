
open Support
open Natives

let known_pures : unit -> ident list =
  fun _ ->
    [
      native_vector_subscript_id;
      native_vector_subset_id;
      native_vector_make_id;
      native_vector_length_id;
      native_vector_colon_id;

      native_vector_add_id;
      native_vector_mul_id;
      native_vector_div_id;
      native_vector_sub_id;
      native_vector_mod_id;
      native_vector_exp_id;

      native_vector_lt_id;
      native_vector_gt_id;
      native_vector_eq_id;
      native_vector_neq_id;
      native_vector_geq_id;
      native_vector_leq_id;

      native_vector_andvec_id;
      native_vector_and_id;
      native_vector_orvec_id;
      native_vector_or_id;
      native_vector_xor_id;

      native_vector_make_symbolic_id;

      native_vector_intconv_id;
      native_vector_floatconv_id;
      native_vector_complexconv_id;
      native_vector_strconv_id;
      native_vector_boolconv_id;
    ]
