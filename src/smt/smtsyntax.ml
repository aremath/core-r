
(* cf p24: https://smtlib.github.io/jSMTLIB/SMTLIBTutorial.pdf *)

type smtlogic =
  | SmtALL
  | SmtQFLIA
  | SmtQFLRA
  | SmtQFNIA
  | SmtQFNRA
  | SmtQFLIRA
  | SmtQFNIRA

type smtvar = string

type smtconst = string

type smtsort =
  | SmtSortInt
  | SmtSortFloat
  | SmtSortDouble
  | SmtSortBool
  | SmtSortVar of smtvar * smtsort list

type smtexpr =
  | SmtVar of smtvar
  | SmtConst of smtconst

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
  | SmtNeg of smtexpr
  | SmtImp of smtexpr * smtexpr
  | SmtIff of smtexpr * smtexpr

  (* Arithmetics *)
  | SmtPlus of smtexpr * smtexpr
  | SmtSub of smtexpr * smtexpr
  | SmtMult of smtexpr * smtexpr
  | SmtDiv of smtexpr * smtexpr
  | SmtExp of smtexpr * smtexpr
  | SmtMod of smtexpr * smtexpr
  | SmtRem of smtexpr * smtexpr

  (* Array Operations *)
  | SmtArrGet of smtexpr * smtexpr
  | SmtArrSet of smtexpr * smtexpr * smtexpr

  (* Function Calls *)
  | SmtFunApp of smtvar * smtexpr list

  (* Let expressions *)
  | SmtLet of (smtvar * smtexpr) list * smtexpr

  (* Quantifiers *)
  | SmtForAll of (smtvar * smtsort) list * smtexpr
  | SmtExists of (smtvar * smtsort) list * smtexpr


type smtcmd =
  (* Set logic *)
  | SmtSegLogic of smtlogic

  (* Declarations *)
  | SmtDeclFun of smtvar * smtvar list * smtsort
  | SmtDefFun of smtvar
  | SmtDeclSort of smtvar * int
  | SmtDefSort of smtvar * smtvar list * smtsort

  (* Assertions *)
  | SmtAssert of smtexpr

  (* Model querying *)
  | SmtCheckSat
  | SmtGetModel
  | SmtPush
  | SmtPop
  | SmtExit


