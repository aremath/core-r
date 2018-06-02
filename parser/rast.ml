type source =
  { file : string
  ; line : int
  ; col  : int }


type 'a ident =
  { pkg  : string option
  ; name : string
  ; src  : source option
  ; tag  : 'a option }


let default_ident =
  { pkg  = None
  ; name = ""
  ; src  = None
  ; tag  = None }


type numeric =
    Unconverted of string
  | Int of int
  | Float of float
  | Complex of float * float
  | Na


type unop =
    UMinus (* - *)
  | UPlus  (* + *)
  | Not    (* ! *)
  | UForm  (* ~ *)
  | UHelp  (* ? *)


type binop =
  (* Numerical *)
    Plus
  | Minus
  | Mult
  | Div
  | Exp
  | Mod
  | IntDiv
  | MatrixMult
  | OuterProd
  | KronProd
  | Match
  (* Boolean *)
  | Gt
  | Ge
  | Lt
  | Le
  | Eq
  | Neq
  | AndVec
  | And
  | Or
  | OrVec
  (* Assignment *)
  | Assign
  | SuperAssign
  (* List access *)
  | ObjAttr
  (* List ranges *)
  | Range
  (* What the hell is this *)
  | Form
  (* Qualified namespace lookup *)
  | GetPackage
  | GetPackageInt
  (* Help?? *)
  | Help


type 'a arg =
  (* Expression *)
    ExprArg of 'a expr
  (* Assignments *)
  | IdentAssignEmpty of 'a ident
  | IdentAssign of 'a ident * 'a expr
  | StringAssignEmpty of string
  | StringAssign of string * 'a expr
  | NullAssignEmpty
  | NullAssign of 'a expr
  (* Variadic argument *)
  | ArgDots


and 'a param =
    Param of 'a ident
  | DefaultParam of 'a ident * 'a expr
  | ParamDots


and 'a expr =
  (* New lines *)
  | LeftNewLines of 'a expr
  | RightNewLines of 'a expr
  (* Constants *)
  | NumericConst of numeric
  | StringConst of string
  | BoolConst of bool
  (* Valued constants *)
  | Null
  (* Identifiers *)
  | Ident of 'a ident
  (* Unary and binary operators *)
  | Uop of unop * 'a expr
  | Bop of binop * 'a expr * 'a expr
  (* Function declaration and calls *)
  | FuncCall of 'a expr * ('a arg) list
  | FuncDec of ('a param) list * 'a expr
  (* Expression blocks *)
  | Block of 'a expr list            (* {} *)
  (* List Operations *)
  | ListProj of 'a expr * ('a arg) list
  | ListSub of 'a expr * ('a arg) list
  (* Control structures *)
  | If of 'a expr * 'a expr (* empty block is like {NA}?*)
  | IfElse of 'a expr * 'a expr * 'a expr
  | For of ('a ident * 'a expr) * 'a expr
  | While of 'a expr * 'a expr
  | Repeat of 'a expr
  | Next
  | Break
  (* ? *)


type 'a program = ('a expr) list


(* Useful string conversion functions *)

let string_of_ident : 'a ident -> string =
  fun id -> match id.pkg with
    | Some pkg -> pkg ^ "::" ^ id.name
    | None -> "" ^ id.name

let string_of_numeric : numeric -> string =
  function
    | Na             -> "NA"
    | Unconverted s  -> "Unconverted " ^ s
    | Int i          -> "Int " ^ (string_of_int i)
    | Float f        -> "Float " ^ (string_of_float f)
    | Complex (r, i) -> "Complex (" ^ (string_of_float r) ^ ", " ^
                                      (string_of_float i) ^ ")"

let string_of_unop : unop -> string =
  function
    | UMinus -> "-"
    | UPlus  -> "+"
    | Not    -> "!"
    | UForm  -> "~"
    | UHelp  -> "?"


let string_of_binop : binop -> string =
  function
    | Plus          -> "+"
    | Minus         -> "-"
    | Mult          -> "*"
    | Div           -> "/"
    | Exp           -> "^"
    | Mod           -> "%%"
    | IntDiv        -> "%/%"
    | MatrixMult    -> "%*%"
    | OuterProd     -> "%*%"
    | KronProd      -> "%x"
    | Match         -> "%in%"
    | Gt            -> ">"
    | Ge            -> ">="
    | Lt            -> "<"
    | Le            -> "<="
    | Eq            -> "=="
    | Neq           -> "!="
    | And           -> "&&"
    | AndVec        -> "&"
    | Or            -> "||"
    | OrVec         -> "|"
    | Form          -> "~"
    | Assign        -> "<-"
    | SuperAssign   -> "<<-"
    | ObjAttr       -> "@"
    | Range         -> ":"
    | Help          -> "?"
    | GetPackage    -> "::"
    | GetPackageInt -> ":::"


let rec string_of_expr : 'a expr -> string =
  function
    (* New lines *)
    | LeftNewLines e -> "LN(" ^ (string_of_expr e) ^ ")"
    | RightNewLines e -> "RN(" ^ (string_of_expr e) ^ ")"
    (* Values *)
    | NumericConst i -> "NumericConst " ^ (string_of_numeric i)
    | StringConst s  -> "StringConst " ^ s
    | BoolConst l    -> "BoolConst " ^ (string_of_bool l)
    | Null           -> "Null"
    (* Identifiers *)
    | Ident i -> string_of_ident i
    (* Operators *)
    | Uop (u, e) ->
        "Uop(" ^ (string_of_unop u) ^ "," ^ (string_of_expr e) ^ ")"
    | Bop (b, e1, e2) ->
        "Bop(" ^ (string_of_binop b) ^ "," ^
                 (string_of_expr e1) ^ "," ^ (string_of_expr e2) ^ ")"
    (* Functions *)
    | FuncCall (e, args) ->
        "FuncCall(" ^
         (string_of_expr e) ^ ", [" ^
         (String.concat "," (List.map string_of_arg args)) ^ "])"
    | FuncDec (ps, e) ->
        "FuncDec([" ^
          (String.concat "," (List.map string_of_param ps)) ^ "]," ^
          (string_of_expr e) ^ ")"

    (* Block of expressions *)
    | Block (es) ->
        "Block([" ^ (String.concat "," (List.map string_of_expr es)) ^ "])"
    (* Control expressions *)
    | If (c, et) ->
        "If(" ^ (string_of_expr c) ^ "," ^ (string_of_expr et) ^ ")"
    | IfElse (c, et, ef) ->
        "IfElse(" ^ (string_of_expr c) ^ "," ^
                    (string_of_expr et) ^ "," ^ (string_of_expr ef) ^ ")"
    | For ((i, e2), e3) ->
        "For(" ^ (string_of_ident i) ^ "," ^ (string_of_expr e2) ^ "," ^
                 (string_of_expr e3) ^ ")"
    | While (e1, e2) ->
        "While(" ^ (string_of_expr e1) ^ "," ^ (string_of_expr e2) ^ ")"
    | Repeat (e) -> "Repeat(" ^ (string_of_expr e) ^ ")"
    | Next -> "Next"
    | Break -> "Break"
    (* List acessing *)
    | ListProj (e, args) ->
        "ListProj(" ^
          (string_of_expr e) ^ ",[" ^
          (String.concat "," (List.map string_of_arg args)) ^ "])"
    | ListSub (e, args) ->
        "ListSub(" ^
          (string_of_expr e) ^ ",[" ^
          (String.concat "," (List.map string_of_arg args)) ^ "])"


and string_of_arg : 'a arg -> string =
  function
    | ExprArg e           -> string_of_expr e
    | IdentAssignEmpty i  -> "i="
    | IdentAssign (i, e)  -> "i=" ^ (string_of_expr e)
    | StringAssignEmpty s -> s ^ "="
    | StringAssign (s, e) -> s ^ "=" ^ (string_of_expr e)
    | NullAssignEmpty     -> "Null="
    | NullAssign e        -> "Null=" ^ (string_of_expr e)
    | ArgDots             -> "..."


and string_of_param : 'a param -> string =
  function
    | Param i             -> string_of_ident i
    | DefaultParam (i, e) -> (string_of_ident i) ^ "=" ^ (string_of_expr e)
    | ParamDots           -> "..."


let string_of_program : 'a program -> string =
  fun es ->
    "[" ^ (String.concat "," (List.map string_of_expr es)) ^ "]"


