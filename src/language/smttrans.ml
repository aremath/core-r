open Support
open Smtsyntax

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
    SmtForAll ([(forall_var, SortInt)],
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

let state : state -> smtstmt list =
  fun state ->
    []   

