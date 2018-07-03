module S = Support

(* Perform a non-optional binary operation on options *)
let opt_bop: ('a -> 'a -> 'a) -> 'a option -> 'a option -> 'a option =
    fun f lo ro ->
    match (lo, ro) with
    | (Some l, Some r) -> Some (f l r)
    | _ -> None

(* TODO: Array.map2 introduced in 4.03 but for dumb reasons we're in 4.01.
 This is my best shot at conciseness *)
let array_map2: ('a -> 'b -> 'c) -> 'a array -> 'b array -> 'c array =
    fun f a1 a2 ->
    let l1 = Array.length a1 in
    let l2 = Array.length a2 in
    if l1 = l2 then
        (* Kind of gross *)
        Array.init l1 (fun i -> f a1.(i) a2.(i))
    else
        failwith "Map2 arrays not of same length"

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
    | (S.IntVec l, S.IntVec r) -> S.IntVec (array_map2 fi l r)
    | (S.FloatVec l, S.FloatVec r) -> S.FloatVec (array_map2 ff l r)
    | (S.ComplexVec l, S.ComplexVec r) -> S.ComplexVec (array_map2 fc l r)
    | (S.StrVec l, S.StrVec r) -> S.StrVec (array_map2 fs l r)
    | (S.BoolVec l, S.BoolVec r) -> S.BoolVec (array_map2 fb l r)
    | _ -> failwith "Can't bop vectors with incompatible types"

let add_rint: S.rint -> S.rint -> S.rint = opt_bop (+)
let add_rfloat: S.rfloat -> S.rfloat -> S.rfloat = opt_bop (+.)
let add_rcomplex: S.rcomplex -> S.rcomplex -> S.rcomplex = opt_bop Complex.add

let rvector_add = bop_rvectors
    add_rint
    add_rfloat
    add_rcomplex
    (fun _ _ -> failwith "Non-numeric addition")
    (fun _ _ -> failwith "Non-numeric addition")

let mul_rint: S.rint -> S.rint -> S.rint = opt_bop ( * )
let mul_rfloat: S.rfloat -> S.rfloat -> S.rfloat = opt_bop ( *. )
let mul_rcomplex: S.rcomplex -> S.rcomplex -> S.rcomplex = opt_bop Complex.mul

let rvector_mul = bop_rvectors
    mul_rint
    mul_rfloat
    mul_rcomplex
    (fun _ _ -> failwith "Non-numeric addition")
    (fun _ _ -> failwith "Non-numeric addition")

(* The old way:
(* Combine two rvectors of the same length through addition *)
let add_rvectors: S.rvector -> S.rvector -> S.rvector =
    fun lhs rhs ->
    (* Match the types and add *)
    match (lhs, rhs) with
    | (S.IntVec l, S.IntVec r) -> S.IntVec (Array.map2 add_rint l r)
    | (S.FloatVec l, S.FloatVec r) -> S.FloatVec (Array.map2 add_rfloat l r)
    | (S.ComplexVec l, S.ComplexVec r) -> S.ComplexVec (Array.map2 add_rcomplex l r)
    | (S.StrVec l, S.StrVec r) -> failwith "Non-numeric addition"
    | (S.BoolVec l, S.BoolVec r) -> failwith "Non-numeric addition"
    | _ -> failwith "Can't add vectors with incompatible types"
*)
