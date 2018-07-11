module S = Support
module C = Native_support

(* Perform a non-optional binary operation on options *)
let opt_bop: ('a -> 'b -> 'c) -> ('a option -> 'b option -> 'c option) =
    fun f lo ro ->
    match (lo, ro) with
    | (Some l, Some r) -> Some (f l r)
    | _ -> None


(* Applies five functions to rvectors as cases for each type of rvector.
 Reuses code nicely, but not general in the sense that the operation
 on two float vectors must produce a float vector, and there's no way
 for an operation to work on two vectors with mismatched types. *)
let bop_rvectors: (S.rint -> S.rint -> S.rint) ->
                  (S.rfloat -> S.rfloat -> S.rfloat) ->
                  (S.rcomplex -> S.rcomplex -> S.rcomplex) ->
                  (S.rstring -> S.rstring -> S.rstring) ->
                  (S.rbool -> S.rbool -> S.rbool) ->
                  S.rvector -> S.rvector -> S.rvector =
    fun fi ff fc fs fb lhs rhs ->
    match (lhs, rhs) with
    | (S.IntVec l, S.IntVec r) -> S.IntVec (C.array_map2 fi l r)
    | (S.FloatVec l, S.FloatVec r) -> S.FloatVec (C.array_map2 ff l r)
    | (S.ComplexVec l, S.ComplexVec r) -> S.ComplexVec (C.array_map2 fc l r)
    | (S.StrVec l, S.StrVec r) -> S.StrVec (C.array_map2 fs l r)
    | (S.BoolVec l, S.BoolVec r) -> S.BoolVec (C.array_map2 fb l r)
    | _ -> failwith "Can't bop vectors with incompatible types"

(* Addition *)
let add_rint: S.rint -> S.rint -> S.rint = opt_bop (+)
let add_rfloat: S.rfloat -> S.rfloat -> S.rfloat = opt_bop (+.)
let add_rcomplex: S.rcomplex -> S.rcomplex -> S.rcomplex = opt_bop Complex.add
let add_rstr = (fun _ _ -> failwith "Non-numeric addition")
let add_rbool = (fun _ _ -> failwith "Non-numeric addition")

let rvector_add = bop_rvectors
    add_rint
    add_rfloat
    add_rcomplex
    add_rstr
    add_rbool

(* Multiplication *)
let mul_rint = opt_bop ( * )
let mul_rfloat = opt_bop ( *. )
let mul_rcomplex = opt_bop Complex.mul
let mul_rstr = (fun _ _ -> failwith "Non-numeric multiplication")
let mul_rbool = (fun _ _ -> failwith "Non-numeric multiplication")

let rvector_mul = bop_rvectors
    mul_rint
    mul_rfloat
    mul_rcomplex
    mul_rstr
    mul_rbool

(* Division *)
let div_rint = opt_bop ( / )
let div_rfloat = opt_bop (/.)
let div_rcomplex = opt_bop Complex.div
let div_rstr = (fun _ _ -> failwith "Non-numeric division")
let div_rbool = (fun _ _ -> failwith "Non-numeric division")

let rvector_div = bop_rvectors
    div_rint
    div_rfloat
    div_rcomplex
    div_rstr
    div_rbool

(* Subtraction *)
let sub_rint = opt_bop ( - )
let sub_rfloat = opt_bop ( -. )
let sub_rcomplex = opt_bop Complex.sub
let sub_rstr = (fun _ _ -> failwith "Non-numeric subtraction")
let sub_rbool = (fun _ _ -> failwith "Non-numeric subtraction")

let rvector_sub = bop_rvectors
    sub_rint
    sub_rfloat
    sub_rcomplex
    sub_rstr
    sub_rbool

(* Modulus *)
let mod_rint = opt_bop ( mod )
let mod_rfloat = opt_bop ( mod_float )
let mod_rcomplex = (fun _ _ -> failwith "No complex modulus")
let mod_rstr = (fun _ _ -> failwith "Non-numeric modulus")
let mod_rbool = (fun _ _ -> failwith "Non-numeric modulus")

let rvector_mod = bop_rvectors
    mod_rint
    mod_rfloat
    mod_rcomplex
    mod_rstr
    mod_rbool

(* Exponentiation *)
(* ocaml has no int exponentiation. This works, but is prone to overflow and
 rounding errors *)
let exp_rint = opt_bop (fun i1 i2 -> let f1 = float_of_int i1 in
    let f2 = float_of_int i2 in
    int_of_float (f1 ** f2))
let exp_rfloat = opt_bop ( ** )
let exp_rcomplex = opt_bop Complex.pow
let exp_rstr = (fun _ _ -> failwith "Non-numeric exponentiation")
let exp_rbool = (fun _ _ -> failwith "Non-numeric exponentiation")

let rvector_exp = bop_rvectors
    exp_rint
    exp_rfloat
    exp_rcomplex
    exp_rstr
    exp_rbool

(* Comparison. Like bop_rvectors, but always produces a BoolVec *)
let cmp_rvectors: (S.rint -> S.rint -> S.rbool) ->
                  (S.rfloat -> S.rfloat -> S.rbool) ->
                  (S.rcomplex -> S.rcomplex -> S.rbool) ->
                  (S.rstring -> S.rstring -> S.rbool) ->
                  (S.rbool -> S.rbool -> S.rbool) ->
                  S.rvector -> S.rvector -> S.rvector =
    fun fi ff fc fs fb lhs rhs ->
    match (lhs, rhs) with
    | (S.IntVec l, S.IntVec r) -> S.BoolVec (C.array_map2 fi l r)
    | (S.FloatVec l, S.FloatVec r) -> S.BoolVec (C.array_map2 ff l r)
    | (S.ComplexVec l, S.ComplexVec r) -> S.BoolVec (C.array_map2 fc l r)
    | (S.StrVec l, S.StrVec r) -> S.BoolVec (C.array_map2 fs l r)
    | (S.BoolVec l, S.BoolVec r) -> S.BoolVec (C.array_map2 fb l r)
    | _ -> failwith "Can't bop vectors with incompatible types"

(* Error behavior when comparing two complex numbers *)
let complex_compare_failure = (fun _ _ -> failwith "Complex comparison")

(* Because ocaml comparisons return bool but R bools are int *)
let int_of_bool: bool -> int =
    fun b -> if b then 1 else 0
let bool_of_int: int -> bool =
    fun i -> if i=0 then false else true
let rbool_wrap: ('a -> 'b -> bool) -> ('a -> 'b -> int) =
    fun f l r -> int_of_bool (f l r)

(* Less Than. Thankfully, ocaml does sensible things *)
(* let rlt = rbool_wrap (<) -- Can't do this because the ocaml typechecker is bad :( *)
let lt_rint = opt_bop (rbool_wrap (<))
let lt_rfloat = opt_bop (rbool_wrap (<))
let lt_rcomplex = complex_compare_failure 
let lt_rstr = opt_bop (rbool_wrap (<))
let lt_rbool = opt_bop (rbool_wrap (<))

let rvector_lt = cmp_rvectors
    lt_rint
    lt_rfloat
    lt_rcomplex
    lt_rstr
    lt_rbool

(* Greater Than *)
let gt_rint = opt_bop (rbool_wrap (>))
let gt_rfloat = opt_bop (rbool_wrap (>))
let gt_rcomplex = complex_compare_failure 
let gt_rstr = opt_bop (rbool_wrap (>))
let gt_rbool = opt_bop (rbool_wrap (>))

let rvector_gt = cmp_rvectors
    gt_rint
    gt_rfloat
    gt_rcomplex
    gt_rstr
    gt_rbool

(* Equality. Thankfully R does not have NA == NA *)
(* I could define it once and pass the same function to cmp_rvectors five times
 but I think this is clearer. *)
(* TODO: Note that this can differ subtly from R's behavior if R and ocaml use a different fuzz
 to compare floating point numbers *)
let eq_rint = opt_bop (rbool_wrap (=))
let eq_rfloat = opt_bop (rbool_wrap (=))
let eq_rcomplex = opt_bop (rbool_wrap (=))
let eq_rstr = opt_bop (rbool_wrap (=))
let eq_rbool = opt_bop (rbool_wrap (=))

let rvector_eq = cmp_rvectors
    eq_rint
    eq_rfloat
    eq_rcomplex
    eq_rstr
    eq_rbool

(* Inequality *)
let neq_rint = opt_bop (rbool_wrap (<>))
let neq_rfloat = opt_bop (rbool_wrap (<>))
let neq_rcomplex = opt_bop (rbool_wrap (<>))
let neq_rstr = opt_bop (rbool_wrap (<>))
let neq_rbool = opt_bop (rbool_wrap (<>))

let rvector_neq = cmp_rvectors
    neq_rint
    neq_rfloat
    neq_rcomplex
    neq_rstr
    neq_rbool

(* Greater Than or Equal To *)
let geq_rint = opt_bop (rbool_wrap (>=))
let geq_rfloat = opt_bop (rbool_wrap (>=))
let geq_rcomplex = complex_compare_failure 
let geq_rstr = opt_bop (rbool_wrap (>=))
let geq_rbool = opt_bop (rbool_wrap (>=))

let rvector_geq = cmp_rvectors
    geq_rint
    geq_rfloat
    geq_rcomplex
    geq_rstr
    geq_rbool

(* Less Than or Equal To *)
let leq_rint = opt_bop (rbool_wrap (<=))
let leq_rfloat = opt_bop (rbool_wrap (<=))
let leq_rcomplex = complex_compare_failure 
let leq_rstr = opt_bop (rbool_wrap (<=))
let leq_rbool = opt_bop (rbool_wrap (<=))

let rvector_leq = cmp_rvectors
    leq_rint
    leq_rfloat
    leq_rcomplex
    leq_rstr
    leq_rbool

(* Logic *)

(* convert an ocaml bool function to an R bool function *)
let rboolize: (bool -> bool -> bool) -> (int -> int -> int) =
    fun fb li ri ->
    let lb = bool_of_int li in
    let rb = bool_of_int li in
    int_of_bool (fb lb rb)

(* & - vectorized and *)
(* Does not do coercion for now *)
let andvec_failure = (fun _ _ -> failwith "Non-boolean &")

let and_rint = andvec_failure
let and_rfloat = andvec_failure
let and_rcomplex = andvec_failure
let and_rstr = andvec_failure
let and_rbool = opt_bop (rboolize (&&))

let rvector_andvec = cmp_rvectors
    and_rint
    and_rfloat
    and_rcomplex
    and_rstr
    and_rbool

(* && - non-vectorized only compares first two elements *)
let and_failure = (fun _ -> failwith "Non-boolean &&")

(* *)
let bool_op_rvectors: (S.rbool -> S.rbool -> S.rbool) -> 
        (unit -> S.rvector) -> (* The failure expression. It will not actually produce an rvector *) 
        S.rvector -> S.rvector -> S.rvector =
    fun op fail lhs rhs ->
    match (lhs, rhs) with
    | (S.IntVec l, S.IntVec r) -> fail ()
    | (S.FloatVec l, S.FloatVec r) -> fail ()
    | (S.ComplexVec l, S.ComplexVec r) -> fail ()
    | (S.StrVec l, S.StrVec r) -> fail ()
    | (S.BoolVec l, S.BoolVec r) -> 
        let v = Array.make 1 None in
        v.(0) <- op l.(0) r.(0);
        S.BoolVec v
    | _ -> failwith "Can't bop vectors with incompatible types"

let rvector_and = bool_op_rvectors (opt_bop (rboolize (&&))) and_failure

(* | - vectorized or *)
let orvec_failure = (fun _ _ -> failwith "Non-boolean |")

let or_rint = orvec_failure
let or_rfloat = orvec_failure
let or_rcomplex = orvec_failure
let or_rstr = orvec_failure
let or_rbool = opt_bop (rboolize (||))

let rvector_orvec = cmp_rvectors
    or_rint
    or_rfloat
    or_rcomplex
    or_rstr
    or_rbool

(* || - non-vectorized only compares the first two elements *)
let or_failure = (fun _ -> failwith "Non-boolean ||")

let rvector_or = bool_op_rvectors (opt_bop (rboolize (||))) or_failure

(* xor *)
(* For some reason it seems like R only has vectorized xor *)
let xor_failure = (fun _ _ -> failwith "Non-boolean xor")

let rint_xor = xor_failure
let rfloat_xor = xor_failure
let rcomplex_xor = xor_failure
let rstr_xor = xor_failure
let rbool_xor = opt_bop (rbool_wrap (<>))

let rvector_xor = cmp_rvectors
    rint_xor
    rfloat_xor
    rcomplex_xor
    rstr_xor
    rbool_xor

