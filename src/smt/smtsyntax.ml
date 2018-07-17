
type smtvar = string

type smtsort =
  | SortInt
  | SortFloat
  | SortDouble
  | SortBool
  | SortVar of smtvar * smtsort list

type smtcon = 
  | SmtCon of smtvar * smtsort list

type smtexpr =
  | SmtVar of smtvar

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

  (* Declarations *)
  | SmtDeclVar of smtvar * smtsort
  | SmtDeclSort of smtvar * smtvar list * smtcon list

  (* Assertions *)
  | SmtAssert of smtexpr


let string_of_smtvar : smtvar -> string =
  fun var -> var

let smtvar_of_string : string -> smtvar =
  fun str -> str

(*
let if_in_array_bounds: smtvar -> smtexpr -> smtexpr list =
  fun array_name expr -> 
  SmtForAll ("x", SortInt,
    (SmtImp (SmtAnd (
        SmtGe (SmtVar "x",  0),
        SmtLt (SmtVar "x", SmtFuncCall ("len", [SmtVar array_name])))),
    expr))
*)  


