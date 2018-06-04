
type source =
  { file : string
  ; line : int
  ; col : int }

type 'a ident = 
  { pkg : string option
  ; name : string
  ; src : source option
  ; tag : 'a option }

type numeric =
    Int of int
  | Float of float
  | Complex of float * float
  | Raw of string
  | Na

type const =
    Num of numeric
  | Str of string

type memref =
  { addr : int }

type 'a param =
    Param of 'a ident
  | Default of 'a ident * 'a expr
  | VarParam

and 'a arg =
    Arg of 'a expr
  | Named of 'a ident * 'a expr
  | VarArg

and 'a expr =
    Ident of 'a ident
  | MemRef of memref
  | Const of const
  | ArraySub of 'a expr * 'a expr
  | ObjAttr of 'a expr * 'a expr
  | Seq of 'a expr * 'a expr
  | LambdaAbs of ('a param) list * 'a expr
  | LambdaApp of 'a expr * ('a arg) list
  | Assign of 'a expr * 'a expr
  | SuperAssign of 'a expr * 'a expr
  | ArrayAssign of 'a expr * 'a expr * 'a expr
  | ArraySuperAssign of 'a expr * 'a expr * 'a expr
  | ObjAttrAssign of 'a expr * 'a expr * 'a expr
  | If of 'a expr * 'a expr * 'a expr
  | While of 'a expr * 'a expr
  | For of 'a ident * 'a expr * 'a expr
  | Break
  | Next
  | Error


