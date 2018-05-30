module RAst = struct

type 'a ident =
  { package  : string option
  ; name     : string
  ; src_file : string option
  ; src_line : int option
  ; src_col  : int option
  ; tag      : 'a option }


let default_ident =
  { package  = None
  ; name     = ""
  ; src_file = None
  ; src_line = None
  ; src_col  = None
  ; tag      = None }


type uop =
    UMinus (* - *)
  | UPlus  (* + *)
  | Not    (* ! *)
  | UForm  (* ~ *)
  | Help   (* ? *)


type binop =
  (* Numerical *)
    Plus
  | Minus
  | Mult
  | Div
  | Exp
  (* Boolean *)
  | Gt
  | Ge
  | Lt
  | Le
  | Eq
  | Neq
  (* What the hell is this *)
  | Form


type 'a arg = 
  (* Expression *)
    ArgExpr of 'a expr
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
    ConstI of int
  | ConstS of string
  | ConstF of float
  | ConstC of float (* complex *)
  | ConstL of bool  (* 'logical' *)
  (* Valued constants *)
  | Null
  | Na
  (* Identifiers and assignments *)
  | Ident of 'a ident
  | Assign of 'a ident * 'a expr
  | SuperAssign of 'a ident * 'a expr
  (* Unary and binary operators *)
  | Uop of uop * 'a expr
  | Bop of binop * 'a expr * 'a expr
  (* Property and index accessors *)
  | ListProj of 'a expr * ('a arg) list (* [[]], $ *)
  | ListSub of 'a expr * ('a arg) list  (* [] *)
  | ObjAttr of 'a expr * 'a ident
  (* Function declaration and calls *)
  | FuncCall of 'a expr * ('a arg) list
  | FuncDec of 'a expr * ('a param) list
  (* Expression blocks *)
  | Block of 'a expr list            (* {} *)
  (* Control structures *)
  | If of 'a expr * 'a expr * 'a expr (* empty block is like {NA}?*)
  | For of 'a ident * 'a expr * 'a expr
  | While of 'a expr * 'a expr
  | Repeat of 'a expr
  | Next
  | Break


type 'a prog = ('a expr) list


(* Useful string conversion functions *)

let string_of_ident : 'a ident -> string =
  fun id -> match id.package with
      Some pkg -> pkg ^ "::" ^ id.name
    | None -> "" ^ id.name


let string_of_uop : uop -> string =
  function
      UMinus -> "-"
    | UPlus  -> "+"
    | Not    -> "!"
    | UForm  -> "~"
    | Help   -> "?"


let string_of_binop =
  function
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


let rec string_of_expr = function
    | ConstI i -> "ConstI " ^ (string_of_int i)
    | ConstS s -> "ConstS " ^ s
    | ConstF f -> "ConstF " ^ (string_of_float f)
    | ConstC c -> "ConstC " ^ (string_of_float c)
    | ConstL l -> "ConstL " ^ (string_of_bool l)
    | Null -> "Null"
    | Na -> "NA"

    | Ident i -> string_of_ident i
    | Assign (i, e) -> "Assign(" ^ (string_of_ident i) ^ "," ^
                                   (string_of_expr e) ^ ")"
    | SuperAssign (i, e) -> "SuperAssign(" ^ (string_of_ident i) ^ "," ^
                                             (string_of_expr e) ^ ")"
    | Uop (u, e) -> "Uop(" ^ (string_of_uop u) ^ "," ^
                             (string_of_expr e) ^ ")"
    | Bop (b, e1, e2) -> "Bop(" ^ (string_of_binop b) ^ "," ^
                                  (string_of_expr e1) ^ "," ^
                                  (string_of_expr e2) ^ ")"
    | ListProj (e, args) -> "ListProj(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | ListSub (e, args) -> "ListSub(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | ObjAttr (e, i) -> "ObjAttr(" ^ (string_of_expr e) ^ "," ^
                                     (string_of_ident i) ^ ")"

    | FuncCall (e, args) -> "FuncCall(" ^ (string_of_expr e) ^ ", [" ^
        String.concat "," (List.map string_of_arg args) ^ "])"
    | FuncDec (e, params) -> "FuncDec(" ^ (string_of_expr e) ^ ", [" ^
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

    | Next -> "Next"
    | Break -> "Break"



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
    | DefaultParam (i, e) -> (string_of_ident i) ^ "=" ^ (string_of_expr e)
    | ParamDots    -> "..."


end


