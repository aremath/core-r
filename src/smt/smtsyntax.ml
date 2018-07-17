
(* cf p24: https://smtlib.github.io/jSMTLIB/SMTLIBTutorial.pdf *)

type smtvar = string

type smtsort =
  | SortInt
  | SortFloat
  | SortDouble
  | SortBool
  | SortVar of smtvar * smtsort list

type smtexpr =
  | SmtVar of smtvar
  | SmtConst of string

  (* Equality comparison predicates *)
  | SmtGt of smtexpr * smtexpr
  | SmtGe of smtexpr * smtexpr
  | SmtLt of smtexpr * smtexpr
  | SmtLe of smtexpr * smtexpr
  | SmtEq of smtexpr * smtexpr
  | SmtNeq of smtexpr * smtexpr

  (* Logical conjunctions *)
  | SmtAnd of smtexpr * smtexpr
  | SmtOr of smtexpr * smtexpr
  | SmtNeg of smtexpr * smtexpr
  | SmtImp of smtexpr * smtexpr
  | SmtIff of smtexpr * smtexpr

  (* Arithmetics *)
  | SmtPlus of smtexpr * smtexpr
  | SmtSub of smtexpr * smtexpr
  | SmtMult of smtexpr * smtexpr
  | SmtDiv of smtexpr * smtexpr
  | SmtExp of smtexpr * smtexpr
  | SmtMod of smtexpr * smtexpr

  (* Array Operations *)
  | SmtArrGet of smtexpr * smtexpr
  | SmtArrSet of smtexpr * smtexpr

  (* Function Calls *)
  | SmtFunApp of smtvar * smtexpr list

  (* Let expressions *)
  | SmtLet of (smtvar * smtexpr) list * smtexpr

  (* Quantifiers *)
  | SmtForAll of (smtvar * smtsort) list * smtexpr
  | SmtExists of (smtvar * smtsort) list * smtexpr


  (* Declarations *)
  | SmtDeclVar of smtvar * smtsort
  | SmtDeclFun of smtvar * smtvar list * smtexpr
  | SmtDeclSort of smtvar * int
  | SmtDefSort of smtvar * smtvar list * smtsort

  (* Assertions *)
  | SmtAssert of smtexpr


let string_of_smtvar : smtvar -> string =
  fun var -> var

let smtvar_of_string : string -> smtvar =
  fun str -> str

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

(* Assert expr across all valid indices of array_name.
  When using this, use forall_var to refer to the index. For example,

    all_elements a (SmtLt (SmtVar i, smt_int_const 10))

  asserts that i < 10 for all i within the bounds of a. If len(a) >= 10 then
  this is unsat.
*)
let all_elements: smtvar -> smtexpr -> smtexpr =
    fun array_name expr ->
    SmtForAll ([(forall_var, SortInt)],
        (SmtImp ((SmtAnd (
            SmtGe (SmtVar forall_var, smt_int_const 0),
            SmtLt (SmtVar forall_var, smt_len array_name))),
        expr)))

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


