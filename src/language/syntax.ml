
type 'a ident = 
  { pkg : string option;
    name : string;
    ident_tag : 'a option }

type 'b tick = { tick_tag : 'b }

type numeric =
    Int of int option
  | Float of float option
  | Complex of Complex.t option

type const =
    Num of numeric
  | Str of string option
  | Bool of int option (* bools are stored as 0,1 *)

type memref = { addr : int }

type ('a, 'b) param =
    Param of 'a ident
  | Default of 'a ident * ('a, 'b) expr
  | VarParam

and ('a, 'b) arg =
    Arg of ('a, 'b) expr
  | Named of 'a ident * ('a, 'b) expr
  | VarArg

and ('a, 'b) expr =
    Ident of 'a ident
  | MemRef of memref
  | Const of const
  | ArraySub of ('a, 'b) expr * (('a, 'b) arg) list
  | ObjAttr of ('a, 'b) expr * ('a, 'b) expr
  | Seq of ('a, 'b) expr * ('a, 'b) expr
  | LambdaAbs of (('a, 'b) param) list * ('a, 'b) expr
  | LambdaApp of ('a, 'b) expr * (('a, 'b) arg) list
  | Assign of ('a, 'b) expr * ('a, 'b) expr
  | SuperAssign of ('a, 'b) expr * ('a, 'b) expr
  | ArrayAssign of ('a, 'b) expr * ('a, 'b) expr * ('a, 'b) expr
  | ArraySuperAssign of ('a, 'b) expr * ('a, 'b) expr * ('a, 'b) expr
  | ObjAttrAssign of ('a, 'b) expr * ('a, 'b) expr * ('a, 'b) expr
  | If of ('a, 'b) expr * ('a, 'b) expr * ('a, 'b) expr
  | While of ('a, 'b) expr * ('a, 'b) expr
  | For of 'a ident * ('a, 'b) expr * ('a, 'b) expr
  | Break
  | Next
  | Error
  | Tick of 'b tick * ('a, 'b) expr



