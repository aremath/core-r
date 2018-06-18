
type rint = int option
type rfloat = float option
type rcomplex = Complex.t option
type rbool = int option
type rstring = string option

type 'a ident = 
  { pkg : string option;
    name : string;
    tag : 'a option }

type memref =
  { addr : int }

type 'b tick =
  { annot : 'b }

type numeric =
    Int of rint
  | Float of rfloat
  | Complex of rcomplex

type const =
    Num of numeric
  | Str of rstring
  | Bool of rbool (* bools are stored as 0,1 *)

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
  | Break
  | Next
  | Error
  | Tick of 'b tick * ('a, 'b) expr



