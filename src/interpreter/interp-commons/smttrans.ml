open Smtsyntax
open Support

open List


let string_of_smtvar : smtvar -> string =
  fun var -> var

let smtvar_of_string : string -> smtvar =
  fun str -> str

let smtconst_of_const : const -> smtconst =
  fun const ->
    match const with
    | R.Num rnum ->
      (match rnum with
      | R.Int rint ->
        (match int_of_rint rint with
        | Some i -> string_of_int i
        | None -> "Na_int_")
      | R.Float rfloat ->
        (match float_of_rfloat rfloat with
        | Some f -> string_of_float f
        | None -> "Na_float_")
      | R.Complex rcomplex ->
        failwith "smtconst_of_const: dropping support for complex for now")
        (*
        (match complex_of_rcomplex rcomplex with
        | Some c -> string_of_complex c
        | None -> "Na_complex_"))
        *)
    | R.Str rstr ->
      (match string_of_rstring rstr with
      | Some str -> "\"" ^ str ^ "\""
      | None -> "Na_string_")
    | R.Bool rbool ->
      (match bool_of_rbool rbool with
      | Some b -> string_of_int b
      | None -> "Na_bool_")
    | R.Nil -> "nil"

let smtvar_of_mem : memref -> smtvar =
  fun mem ->
    smtvar_of_string ("mem$" ^ string_of_int mem.R.addr)

let smtvar_of_id : ident -> smtvar =
  fun id ->
    match string_of_rstring id.R.name with
    | Some str -> smtvar_of_string str
    | None -> smtvar_of_string "Na_string_"

let rec smtexpr_of_langexpr : expr -> state -> smtexpr =
  fun expr state -> match expr with
    | R.Ident id -> S.SmtVar (smtvar_of_id id)
    | R.MemRef mem -> S.SmtVar (smtvar_of_mem mem)
    | R.Const const -> S.SmtConst (smtconst_of_const const)
    | _ -> S.SmtVar "boo"


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

(* SMT expression for a[i] *)
let smt_getn: smtvar -> int -> smtexpr =
    fun a i ->
    SmtArrGet (SmtVar a, smt_int_const i)

(* Return a copy of the smtexpr with all instances of var1 replaced with var2 *)
let rec replace: smtvar -> smtvar -> smtexpr -> smtexpr =
  fun var1 var2 e ->
    let vreplace = replace var1 var2 in
    match e with
    | SmtVar v -> if v = var1 then SmtVar var2 else SmtVar v
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
    | SmtMod (e1, e2) -> SmtMod ((vreplace e1), (vreplace e2))
    | SmtRem (e1, e2) -> SmtRem ((vreplace e1), (vreplace e2))

    | SmtArrGet (e1, e2) -> SmtArrGet ((vreplace e1), (vreplace e2))
    | SmtArrSet (e1, e2, e3) -> SmtArrSet ((vreplace e1),
            (vreplace e2),
            (vreplace e3))

    | SmtFunApp (a, es) -> SmtFunApp ((if a = var1 then var2 else a),
                                      List.map (vreplace) es)

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
    | SmtSortApp (vsort, vsorts) ->
        let vsorts' = List.map (replace_sort var1 var2) vsorts in
          if vsort = var1 then SmtSortApp (var2, vsorts')
              else SmtSortApp (vsort, vsorts')

let get_mem_pathcons_list : memref -> heap -> pathcons list =
  fun mem heap ->
    match heap_find mem heap with
    | Some (DataObj (Vec (SymVec (_, _, pc)), _)) -> [pc]
    | _ -> []

let smtcmd_list_of_pathcons : pathcons -> smtcmd list =
  fun path ->
    map (fun e -> SmtAssert e) path.path_list

let smtcmd_list_of_state : state -> smtcmd list =
  fun state ->
    let smems = state.sym_mems in
    let heap = state.heap in
    let paths = concat (map (fun m -> get_mem_pathcons_list m heap) smems) in
    let asserts = concat (map smtcmd_list_of_pathcons paths) in
      asserts
