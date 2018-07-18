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
let concat: smtvar -> smtvec -> smtvec -> smtvec =
    fun new_name (name1, ty1, _) (name2, ty2, _) ->
    let new_ty = match_tys ty1 ty2 in
    (* len(x@y) = len(x) + len(y) *)
    let len = (SmtEq (
        smt_len new_name,
        SmtPlus (smt_len name1, smt_len name2))) in
    (* The constraint that elements 0 through len(a1) are the elements of a1 *)
    let a1_elts = all_elements name1
        (SmtEq (
            SmtArrGet new_name forall_var,
            SmtArrGet name1 forall_var)) in
    (* The constraint that elements len(a1) through len(a1) + len(a2) are the elements of a2 *)
    let a2_elts = all_elements name2
        (SmtEq (
            SmtArrGet new_name (SmtPlus forall_var, smt_len name2),
            SmtArrGet name2 forall_var)) in
    (new_name, new_ty, { S.path_list = [len; a1_elts; a2_elts] }

(* General binary operations on symbolic vectors. Assumes that the warning
 will not be thrown if their lengths aren't compatible. The operator in this case
 must combine smtexprs. For example, the op for plus is expr1 -> expr2 -> SmtPlus (expr1, expr2) *)
let smt_op: smtvar -> (smtexpr -> smtexpr -> smtexpr) -> smtvec -> smtvec -> smtvec =
    fun new_name smt_combo (name1, ty1, _) (name2, ty2, _) ->
    let new_ty = match_tys ty1 ty2 in
    (* The length of a vectorized operator on two vectors is the length of the longer vector *)
    let len = ifelse (SmtGt (smt_len name1), (smtlen name2))
        (SmtEq (smt_len new_name), (smt_len name1))
        (SmtEq (smt_len new_name), (smt_len name2)) in
    (* Modulo the index in the smaller vector *)
    let vals = ifelse (SmtGt (smt_len name1), (smtlen name2))
        (all_elements_eq new_name
            (smt_combo (SmtArrGet name1 forall_var) (SmtArrGet name2 (SmtMod forall_var (smt_len name2)))))
        (all_elements_eq new_name
            (smt_combo (SmtArrGet name1 (SmtMod forall_var (smt_len name1))) (SmtArrGet name2 forall_var)))
        in
    (new_name, new_ty, { S.path_list = [len, vals] })

let smt_plus: smtexpr -> smtexpr -> smtexpr =
    fun e1 e2 -> SmtPlus (e1, e2))

let smt_sub: smtexpr -> smtexpr -> smtexpr =
    fun e1 e2 -> SmtSub (e1, e2)




