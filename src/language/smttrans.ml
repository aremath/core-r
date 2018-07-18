open Support
open Smtsyntax

open List

(* Used at the top level as the variable quantified in ForAlls.
  Because multiple ForAlls can be across the same identifier without conflict,
  we choose a ForAll identifier to avoid introducing a new identifier every
  time we wish to quantify. *)
let forall_var: smtvar = "__forall__"

let smt_int_const: int -> smtexpr =
    fun n -> SmtConst (string_of_int n)
let smt_float_const: float -> smtexpr =
    fun f -> SmtConst (string_of_float f)
let smt_bool_const: bool -> smtexpr =
    fun b -> match b with
    | true -> SmtConst "true"
    | false -> SmtConst "false"
(* Convert an rbool to an SMT bool *)
let smt_rbool_const: int -> smtexpr =
    fun b -> match b with
    | 0 -> SmtConst "false"
    | 1 -> SmtConst "true"
    | _ -> failwith "Non-boolean bool"

(* Refer to the length of v *)
let smt_len: smtvar -> smtexpr =
    fun v -> SmtFunApp ("len", [SmtVar v])

(* Assert that the length of the symbolic array var is
 equal to the actual length of a *)
let smt_len_array: 'a. smtvar -> 'a array -> smtexpr =
    fun v a ->
    SmtEq (
        smt_len v,
        smt_int_const (Array.length a))

(* Assert that lower <= var < upper *)
let bounded: smtvar -> smtexpr -> smtexpr -> smtexpr =
    fun var lower upper ->
    SmtAnd (
        SmtGe (SmtVar var, lower),
        SmtLe (SmtVar var, upper))

(* Assert expr across all valid indices of array_name.
  When using this, use forall_var to refer to the index. For example,

    all_elements a (SmtLt (SmtVar i, smt_int_const 10))

  asserts that i < 10 for all i within the bounds of a. If len(a) >= 10 then
  this is unsat.
*)
let all_elements: smtvar -> smtexpr -> smtexpr =
    fun array_name expr ->
    SmtForAll ([(forall_var, SmtSortInt)],
        (* if var is bounded between 0 and the array len, then expr holds *)
        (SmtImp (bounded forall_var (smt_int_const 0) (smt_len array_name), expr)))

(* Assert a[i] = expr across all valid indices of array_name.
  When using this, use forall_var to refer to the index. For example,

    all_elements_eq a (SmtVar forall_var)

  asserts that a[i] = i for all i within the bounds of a.
 *)
let all_elements_eq: smtvar -> smtexpr -> smtexpr =
    fun array_name expr ->
    all_elements array_name
    (SmtEq (
        SmtArrGet (SmtVar array_name, SmtVar forall_var),
        expr))

(* Ifelse t e1 e2 is two implications:
    t -> e1
    !t -> e2
*)
let ifelse: smtexpr -> smtexpr -> smtexpr -> smtexpr =
    fun test e1 e2 ->
    SmtAnd (
        SmtImp (test, e1),
        SmtImp (SmtNeg test, e2))

(* Return a copy of the smtexpr with all instances of var1 replaced with var2 *)
let rec replace: smtvar -> smtvar -> smtexpr -> smtexpr =
    fun var1 var2 e ->
    let vreplace = replace var1 var2 in
    match e with
    | SmtVar var1 -> SmtVar var2
    | SmtVar a -> SmtVar a
    | SmtConst s -> SmtConst s

    | SmtGt (e1, e2) -> SmtGt ((vreplace e1), (vreplace e2))
    | SmtGe (e1, e2) -> SmtGe ((vreplace e1), (vreplace e2))
    | SmtLt (e1, e2) -> SmtLt ((vreplace e1), (vreplace e2))
    | SmtLe (e1, e2) -> SmtLe ((vreplace e1), (vreplace e2))
    | SmtEq (e1, e2) -> SmtEq ((vreplace e1), (vreplace e2))
    | SmtNeq (e1, e2) -> SmtNeq ((vreplace e1), (vreplace e2))

    | SmtAnd (e1, e2) -> SmtAnd ((vreplace e1), (vreplace e2))
    | SmtOr (e1, e2) -> SmtOr ((vreplace e1), (vreplace e2))
    | SmtNeg e1 -> SmtNeg (vreplace e1)
    | SmtImp (e1, e2) -> SmtImp ((vreplace e1), (vreplace e2))
    | SmtIff (e1, e2) -> SmtIff ((vreplace e1), (vreplace e2))

    | SmtPlus (e1, e2) -> SmtPlus ((vreplace e1), (vreplace e2))
    | SmtSub (e1, e2) -> SmtSub ((vreplace e1), (vreplace e2))
    | SmtMult (e1, e2) -> SmtMult ((vreplace e1), (vreplace e2))
    | SmtDiv (e1, e2) -> SmtDiv ((vreplace e1), (vreplace e2))
    | SmtExp (e1, e2) -> SmtExp ((vreplace e1), (vreplace e2))
    | SmtMod (e1, e2) -> SmtRem ((vreplace e1), (vreplace e2))

    | SmtArrGet (e1, e2) -> SmtArrGet ((vreplace e1), (vreplace e2))
    | SmtArrSet (e1, e2, e3) -> SmtArrSet ((vreplace e1),
            (vreplace e2),
            (vreplace e3))

    | SmtFunApp (var1, es) -> SmtFunApp (var2, List.map (vreplace) es)
    | SmtFunApp (a, es) -> SmtFunApp (a, List.map (vreplace) es)

    | SmtLet (lets, e1) -> SmtLet (
        (List.map (replace_let var1 var2) lets),
        (vreplace e1))

    | SmtForAll (defs, e1) -> SmtForAll (
        (List.map (replace_def var1 var2) defs),
        (vreplace e1))
    | SmtExists (defs, e1) -> SmtExists (
        (List.map (replace_def var1 var2) defs),
        (vreplace e1))

(* Helpers for replace *)
and replace_let: smtvar -> smtvar -> (smtvar * smtexpr) -> (smtvar * smtexpr) =
    fun var1 var2 (v, e) ->
    let e' = replace var1 var2 e in
    if v = var1 then (var2, e')
        else (v, e')

and replace_def: smtvar -> smtvar -> (smtvar * smtsort) -> (smtvar * smtsort) =
    fun var1 var2 (v, s) ->
    if v = var1 then (var2, s)
        else (v, s)

and replace_sort: smtvar -> smtvar -> smtsort -> smtsort =
    fun var1 var2 s ->
    match s with
    | SmtSortInt -> SmtSortInt
    | SmtSortFloat -> SmtSortFloat
    | SmtSortDouble -> SmtSortDouble
    | SmtSortBool -> SmtSortBool
    | SmtSortVar (vsort, vsorts) -> let vsorts' = List.map (replace_sort var1 var2) vsorts in
        if vsort = var1 then SmtSortVar (var2, vsorts')
            else SmtSortVar (vsort, vsorts')

let get_mem_pathcons : memref -> heap -> pathcons list =
  fun mem heap ->
    match heap_find mem heap with
    | Some (DataObj (Vec (SymVec (_, _, pc)), _)) -> [pc]
    | _ -> []

let smtstmt_list_of_pathcons : pathcons -> smtstmt list =
  fun path ->
    map (fun e -> SmtAssert e) path.path_list

let state : state -> smtstmt list =
  fun state ->
    let smems = state.sym_mems in
    let paths = concat (map (fun m -> get_mem_pathcons m state.heap) smems) in
    let asserts = concat (map smtstmt_list_of_pathcons paths) in
      asserts

