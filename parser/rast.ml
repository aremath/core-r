module RAst = struct

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


type uop =
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
  | KroneckerProd
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
  | ListProj
  | ListSub
  | ObjAttr
  (* List ranges *)
  | Range
  (* What the hell is this *)
  | Form
  (* Help?? *)
  | Help


type 'a arg =
  (* Expression *)
    ExprArg of 'a expr
  (* Assignments *)
  | IdAssignEmpty of 'a ident
  | IdAssign of 'a ident * 'a expr
  | StrAssignEmpty of string
  | StrAssign of string * 'a expr
  | NullAssignEmpty
  | NullAssign of 'a expr
  (* Variadic argument *)
  | ArgDots


and 'a param =
    Param of 'a ident
  | DefaultParam of 'a ident * 'a expr
  | ParamDots


and 'a expr =
  (* Constants *)
    ConstNum of numeric
  | ConstString of string
  | ConstBool of bool
  (* Valued constants *)
  | Null
  | Na
  (* Identifiers *)
  | Ident of 'a ident
  (* Unary and binary operators *)
  | Uop of uop * 'a expr
  | Bop of binop * 'a expr * 'a expr
  (* Function declaration and calls *)
  | FuncCall of 'a expr * ('a arg) list
  | FuncDec of ('a param) list * 'a expr
  (* Expression blocks *)
  | Block of 'a expr list            (* {} *)
  (* Control structures *)
  | If of 'a expr * 'a expr * 'a expr (* empty block is like {NA}?*)
  | For of 'a ident * 'a expr * 'a expr
  | While of 'a expr * 'a expr
  | Repeat of 'a expr
  | Next
  | Break
  (* ? *)


type 'a prog = ('a expr) list


(* Useful string conversion functions *)

let string_of_ident : 'a ident -> string =
  fun id -> match id.pkg with
      Some pkg -> pkg ^ "::" ^ id.name
    | None -> "" ^ id.name


let string_of_uop : uop -> string =
  function
      UMinus -> "-"
    | UPlus  -> "+"
    | Not    -> "!"
    | UForm  -> "~"
    | UHelp   -> "?"


let string_of_binop =
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
    | KroneckerProd -> "%x"
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
    | ListProj      -> "[[]]"
    | ListSub       -> "[]"
    | ObjAttr       -> "@"
    | Range         -> ":"
    | Help          -> "?"


let rec string_of_expr = function
    | ConstInt i     -> "ConstInt " ^ (string_of_int i)
    | ConstString s  -> "ConstString " ^ s
    | ConstFloat f   -> "ConstFloat " ^ (string_of_float f)
    | ConstComplex c -> "ConstComplex " ^ (string_of_float c)
    | ConstBool l    -> "ConstBool " ^ (string_of_bool l)
    | Null           -> "Null"
    | Na             -> "NA"

    | Ident i -> string_of_ident i
    | Uop (u, e) -> "Uop(" ^ (string_of_uop u) ^ "," ^
                             (string_of_expr e) ^ ")"
    | Bop (b, e1, e2) -> "Bop(" ^ (string_of_binop b) ^ "," ^
                                  (string_of_expr e1) ^ "," ^
                                  (string_of_expr e2) ^ ")"

    | FuncCall (e, args) -> "FuncCall(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | FuncDec (params, e) -> "FuncDec([" ^
                 String.concat "," (List.map string_of_param params) ^
                 "], " ^ (string_of_expr e) ^ ")"
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

    | Next -> "Next"
    | Break -> "Break"


and string_of_arg = function
    | ExprArg e        -> string_of_expr e
    | IdAssignEmpty i  -> "i="
    | IdAssign (i, e)  -> "i=" ^ (string_of_expr e)
    | StrAssignEmpty s -> s ^ "="
    | StrAssign (s, e) -> s ^ "=" ^ (string_of_expr e)
    | NullAssignEmpty  -> "Null="
    | NullAssign e     -> "Null=" ^ (string_of_expr e)
    | ArgDots          -> "..."


and string_of_param = function
    | Param i      -> string_of_ident i
    | DefaultParam (i, e) -> (string_of_ident i) ^ "=" ^ (string_of_expr e)
    | ParamDots    -> "..."


end


