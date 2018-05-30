module RAst

type ident =
  { package  : string option
  , name     : string
  , src_file : string option
  , src_line : int option
  , src_col  : int option }

let default_ident =
  { package  = None
  , name     = ""
  , src_file = None
  , src_line = None
  , src_col  = None }

let string_of_ident : ident -> string =
  fun id ->
    (Option.get (package id), name id)

type prog = expr list

type uop = NegOp (* - *)
         | PosOp (* + *)
         | NotOp (* ! *)
         | UForm (* ~ *)
         | Help  (* ? *)

let string_of_uop = function
    | NegOp -> "-"
    | PosOp -> "+"
    | NotOp -> "!"
    | UForm -> "~"
    | Help  -> "?"

type binop = Plus (* + *)
        | Minus
        | Mult
        | Div
        | Exp
        | Gt
        | Ge
        | Lt
        | Le
        | Eq
        | Neq
        | Form

let string_of_binop = function
        | Plus  -> "+"
        | Minus -> "-"
        | Mult  -> "*"
        | Div   -> "/"
        | Exp   -> "^"
        | Gt    -> ">"
        | Ge    -> ">="
        | Lt    -> "<"
        | Le    -> "<="
        | Eq    -> "=="
        | Neq   -> "!="
        | Form  -> "~"

(*TODO: better name*)
type arg = ArgExpr of expr
        | IdAssignEmpty of ident
        | IdAssign of ident * expr
        | StrAssignEmpty of string
        | StrAssign of string *  expr
        | NullAssignEmpty
        | NullAssign of expr
        | ArgDots

and param = Param of ident
        | Named of ident * expr
        | ParamDots

and expr = ConstI of int
        | ConstS of string
        | ConstF of float
        | ConstC of float (* complex *)
        | ConstL of bool  (* 'logical' *)

        | Ident of ident

        | Assign of ident * expr
        | SuperAssign of ident * expr

        | Uop of uop * expr
        | Bop of binop * expr * expr

        | ListProj of expr * arg list (* [[]], $ *)
        | ListSub of expr * arg list  (* [] *)
        | ObjAttr of expr * ident

        | Func of expr * arg list
        | FuncDefine of expr * param list

        | Block of expr list            (* {} *)

        | If of expr * expr * expr (* empty block is like {NA}?*)
        | For of ident * expr * expr
        | While of expr * expr
        | Repeat of expr
        | Null
        | NA
        | Next
        | Break


let rec string_of_expr = function
    | ConstI i -> "ConstI " ^ (string_of_int i)
    | ConstS s -> "ConstS " ^ s
    | ConstF f -> "ConstF " ^ (string_of_float f)
    | ConstC c -> "ConstC " ^ (string_of_float c)
    | ConstL l -> "ConstL " ^ (string_of_bool l)
    | Null -> "Null"
    | NA -> "NA"
    | Assign (i, e) -> "Assign(" ^ (string_of_ident i) ^ "," ^
                                   (string_of_expr e) ^ ")"
    | SuperAssign (i, e) -> "SuperAssign(" ^ (string_of_ident i) ^ "," ^
                                             (string_of_expr e) ^ ")"
    | Next -> "Next"
    | Break -> "Break"
    | Uop (u, e) -> "Uop(" ^ (string_of_uop u) ^ "," ^ (string_of_expr e) ^ ")"
    | Bop (b, e1, e2) -> "Bop(" ^ (string_of_binop b) ^ "," ^
                                  (string_of_expr e1) ^ "," ^
                                  (string_of_expr e2) ^ ")"
    | ListProj (e, args) -> "ListProj(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | ListSub (e, args) -> "ListSub(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | Func (e, args) -> "Func(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | FuncDefine (e, params) -> "FuncDefine(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_param params) ^ "])"
    | Block (es) -> "Block([" ^
                    (String.concat "," (List.map string_of_expr es)) ^"])"
    | If (e1, e2, e3) -> "If(" ^ (string_of_expr e1) ^ "," ^
                                 (string_of_expr e2) ^ "," ^
                                 (string_of_expr e3) ^ ")"
    | For (i, e2, e3) -> "For(" ^ (string_of_ident i) ^ "," ^
                                  (string_of_expr e2) ^ "," ^
                                  (string_of_expr e3) ^ ")"
    | While (e1, e2) -> "While(" ^ (string_of_expr e1) ^ "," ^
                                   (string_of_expr e2) ^ "," ^ ")"
    | Repeat (e) -> "Repeat(" ^ (string_of_expr e) ^ ")"

and string_of_arg = function
    | ArgExpr e        -> string_of_expr e
    | IdAssignEmpty i  -> "i="
    | IdAssign (i, e)  -> "i=" ^ (string_of_expr e)
    | StrAssignEmpty s -> s ^ "="
    | StrAssign (s, e) -> s ^ "=" ^ (string_of_expr e)
    | NullAssignEmpty  -> "Null="
    | NullAssign e     -> "Null=" ^ (string_of_expr e)
    | ArgDots          -> "..."

and string_of_param = function
    | Param i      -> string_of_ident i
    | Named (i, e) -> (string_of_ident i) ^ "=" ^ (string_of_expr e)
    | ParamDots    -> "..."




