module S = Support
open Smtsyntax
open Smttrans

type smtvec = (smtvar * S.rtype * S.pathcons)

let match_tys: S.rtype -> S.rtype -> S.rtype =
    fun ty1 ty2 ->
    match (ty1, ty2) with
    | (S.RInt, S.RInt) -> S.RInt
    | (S.RFloat, S.RFloat) -> S.RFloat
    | (S.RComplex, S.RComplex) -> S.RComplex
    | (S.RString, S.RString) -> S.RString
    | (S.RBool, S.RBool) -> S.RBool
    | (_, _) -> failwith "Incompatible symbolic types"
    
(* From two symbolic vectors, make a new symbolic vector which is
 constrained to be the concatenation of v1 and v2. *)
let symbolic_concat: smtvar -> smtvec -> smtvec -> smtvec =
    fun new_name (name1, ty1, _) (name2, ty2, _) ->
    let new_ty = match_tys ty1 ty2 in
    (* len(x@y) = len(x) + len(y) *)
    let len = (SmtEq (
        smt_len new_name,
        SmtPlus (smt_len name1, smt_len name2))) in
    (* The constraint that elements 0 through len(a1) are the elements of a1 *)
    let a1_elts = all_elements name1
        (SmtEq (
            SmtArrGet (SmtVar new_name, SmtVar forall_var),
            SmtArrGet (SmtVar name1, SmtVar forall_var))) in
    (* The constraint that elements len(a1) through len(a1) + len(a2) are the elements of a2 *)
    let a2_elts = all_elements name2
        (SmtEq (
            SmtArrGet (SmtVar new_name, (SmtPlus (SmtVar forall_var, smt_len name2))),
            SmtArrGet (SmtVar name2, SmtVar forall_var))) in
    (new_name, new_ty, { S.path_list = [len; a1_elts; a2_elts] })

(* General binary operations on symbolic vectors. Assumes that the warning
 will not be thrown if their lengths aren't compatible. The operator in this case
 must combine smtexprs. For example, the op for plus is expr1 -> expr2 -> SmtPlus (expr1, expr2) *)
let symbolic_op: smtvar -> (smtexpr -> smtexpr -> smtexpr) -> smtvec -> smtvec -> smtvec =
    fun new_name smt_combo (name1, ty1, _) (name2, ty2, _) ->
    let new_ty = match_tys ty1 ty2 in
    (* The length of a vectorized operator on two vectors is the length of the longer vector *)
    let len = ifelse (SmtGt ((smt_len name1), (smt_len name2)))
        (SmtEq ((smt_len new_name), (smt_len name1)))
        (SmtEq ((smt_len new_name), (smt_len name2))) in
    (* Modulo the index in the smaller vector *)
    let vals = ifelse (SmtGt ((smt_len name1), (smt_len name2)))
        (all_elements_eq new_name
            (smt_combo (SmtArrGet (SmtVar name1, SmtVar forall_var)) 
                (SmtArrGet (SmtVar name2, (SmtMod (SmtVar forall_var, (smt_len name2)))))))
        (all_elements_eq new_name
            (smt_combo (SmtArrGet (SmtVar name1, (SmtMod (SmtVar forall_var, (smt_len name1)))))
                (SmtArrGet (SmtVar name2, SmtVar forall_var))))
        in
    (new_name, new_ty, { S.path_list = [len; vals] })

(* Binary operations - ops are all smtexpr -> smtexpr -> smtexpr *)

let symbolic_plus_op: smtexpr -> smtexpr -> smtexpr =
    fun e1 e2 -> SmtPlus (e1, e2)
let symbolic_sub_op = fun e1 e2 -> SmtSub (e1, e2)
(* TODO: Division by zero in SMT is undefined, meaning that the result of such a division can
  be anything SMT wants it to be. y/0 = x is satisfiable, for all values of x, and does not
  depend on the value of y. In R, 1/0 = Inf, and -1/0 = -Inf, because it's doing double division.
  Probably R errors out when dividing literal integers 1/0. We'd like the symbolic behavior to mirror
  R's behavior, with a catch - it seems like there's no way to get Z3 to throw an exception, but we'd like
  to error out somehow if the constraint (Exists x.  Get a2 x = 0) is satisfiable. For now,
  we're just not going to let anyone do symbolic division. *)
let symbolic_div_op: smtexpr -> smtexpr -> smtexpr =
    fun e1 e2 -> SmtDiv (e1, e2)
let symbolic_mul_op = fun e1 e2 -> SmtMult (e1, e2)
(* TODO: SmtMod is defined for integers - might have to encode our own floating-point
  modulus axioms. *)
let symbolic_mod_op = fun e1 e2 -> SmtMod (e1, e2)
(* TODO: is this integer exp, real exp, float exp? all three? *)
let symbolic_exp_op = fun e1 e2 -> SmtExp (e1, e2)

(* Symbolic comparison is the same as any other binop, but the result is a symbolic
  bool vector. *)
let symbolic_cmp: smtvar -> (smtexpr -> smtexpr -> smtexpr) -> smtvec -> smtvec -> smtvec =
    fun new_name smt_combo v1 v2 ->
    let (op_name, op_ty, op_pcs) = symbolic_op new_name smt_combo v1 v2 in
    (op_name, S.RBool, op_pcs)

(* TODO: Determine the domains of these functions! Don't want to produce a PC like
  "hello" > "fish" then not have SMT be able to solve just because R allows > for strs, but
  SMTLIB does not. *)
let symbolic_lt_op: smtexpr -> smtexpr -> smtexpr =
    fun e1 e2 -> SmtLt (e1, e2)
let symbolic_gt_op = fun e1 e2 -> SmtGt (e1, e2)
let symbolic_eq_op = fun e1 e2 -> SmtEq (e1, e2)
let symbolic_neq_op = fun e1 e2 -> SmtNeq (e1, e2)
let symbolic_geq_op = fun e1 e2 -> SmtGe (e1, e2)
let symbolic_leq_op = fun e1 e2 -> SmtLe (e1, e2)

(* A symbolic vectorized operation for booleans only - & and |.
  Do v1 & v2 by using (symbolic_bool_vec_op symbolic_and_op symbolic_andvec_failure) *)
let symbolic_bool_vec_op: smtvar -> (smtexpr -> smtexpr -> smtexpr) ->
        (unit -> smtvec) -> 
        smtvec -> smtvec -> smtvec =
    fun new_name smt_combo fail v1 v2 ->
    let (op_name, op_ty, op_pcs) = symbolic_op new_name smt_combo v1 v2 in
    match op_ty with
    | RBool -> (op_name, op_ty, op_pcs)
    | _ -> fail ()

let symbolic_andvec_failure = fun _ -> failwith "Non-boolean symbolic &"
let symbolic_and_failure = fun _ -> failwith "Non-boolean symbolic &&"
let symbolic_and_op = fun e1 e2 -> SmtAnd (e1, e2)

let symbolic_orvec_failure = fun _ -> failwith "Non-boolean symbolic |"
let symbolic_or_failure = fun _ -> failwith "Non-boolean symbolic ||"
let symbolic_or_op = fun e1 e2 -> SmtOr (e1, e2)

(* A symbolic single operation for booleans only - && and ||.
  Do v1 && v2 by using (symbolic_bool_single_op smybolic_and_op symbolic_and_failure) *)
let symbolic_bool_single_op: smtvar -> (smtexpr -> smtexpr -> smtexpr) ->
        (unit -> smtvec) ->
        smtvec -> smtvec -> smtvec =
    fun new_name smt_combo fail (name1, ty1, _) (name2, ty2, _) ->
    (* If they're both symbolic bool vectors, then make a vector of length 1
      with the appropriate path constraints *)
    match match_tys ty1 ty2 with
    | S.RBool -> let len = SmtEq (
            smt_len new_name,
            smt_int_const 1) in
            (* Constrain value[0] to be the combo of name1[0] and name2[0].*)
            let value = SmtEq (
                SmtArrGet (SmtVar new_name, (smt_int_const 0)),
                smt_combo (SmtArrGet (SmtVar name1, (smt_int_const 0)))
                    (SmtArrGet (SmtVar name2, (smt_int_const 0)))) in
            (new_name, S.RBool, { S.path_list = [len; value] })
    | _ -> fail ()

(* Copies a symbolic vector, introducing a new symbolic vector with a different name,
  and the same path constraints induced over the new name. *)
let copy_symbolic: smtvar -> smtvec -> smtvec =
    fun new_name (name1, ty1, pc1) ->
    let new_pathcons = List.map (replace name1 new_name) pc1.S.path_list in
    (new_name, ty1, { S.path_list = new_pathcons })

(* Symbolic get: smtvec -> int -> smtvec maybe also smtvec -> smtvec -> smtvec *)


