
open Syntax
open Support

let string_of_list : ('a -> string) -> 'a list -> string =
  fun f xs ->
    "[" ^ String.concat "," (List.map f xs) ^ "]"

(*
let rec string_of_source : source -> string =
  fun src ->
    "source {file:" ^ src.file ^ ";" ^
            "line:" ^ string_of_int src.line ^ ";" ^
            "col:" ^ string_of_int src.col ^ "}"
*)

let rec string_of_ident : ident -> string =
  fun id -> match id.pkg with
    | None -> "ident {pkg:" ^ "_" ^ ";name:" ^ id.name ^ "}"
    | Some p -> "ident {pkg:" ^ p ^ ";name:" ^ id.name ^ "}"

and string_of_memref : memref -> string =
  fun mem ->
    "addr: " ^ string_of_int mem.addr

and string_of_numeric : numeric -> string =
  fun num -> match num with
    | Int (Some i)      -> "Int (" ^ string_of_int i ^ ")"
    | Int None          -> "Int (Na)"
    | Float (Some f)    -> "Float (" ^ string_of_float f ^ ")"
    | Float None        -> "Float (Na)"
    | Complex (Some c)  -> "Complex (" ^ string_of_float (c.Complex.re) ^ "," ^
                                 string_of_float (c.Complex.im) ^ ")"
    | Complex None      -> "Complex (Na)"
    
and string_of_const : const -> string =
  fun const -> match const with
    | Num n         -> "Num (" ^ string_of_numeric n ^ ")"
    | Str (Some s)  -> "Str (" ^ s ^ ")"
    | Str None      -> "Str (Na)"
    | Bool (Some b) -> "Bool (" ^ string_of_int b ^ ")"
    | Bool None     -> "Bool (Na)"
    | Nil           -> "Nil"

and string_of_param : param -> string =
  fun param -> match param with
    | VarParam -> "..."
    | Param i -> "Param (" ^ string_of_ident i ^ ")"
    | Default (i, e) -> "Default (" ^ string_of_ident i ^ "," ^
                                      string_of_expr e ^ ")"

and string_of_arg : arg -> string =
  fun arg -> match arg with
    | VarArg -> "..."
    | Arg e -> "Arg (" ^ string_of_expr e ^ ")"
    | Named (i, e) -> "Named (" ^ string_of_ident i ^ "," ^
                                  string_of_expr e ^ ")"

and string_of_tick : tick -> string =
  fun tick ->
    "tick {info:" ^ "_" ^ "}"

and string_of_expr : expr -> string =
  fun expr -> match expr with
    | Ident i -> "Ident (" ^ string_of_ident i ^ ")"
    | MemRef m -> "MemRef (" ^ string_of_memref m ^ ")"
    | Const c -> "Const (" ^ string_of_const c ^ ")"
    | ArraySub (e1, e2s) -> "ArraySub (" ^
                              string_of_expr e1 ^ "," ^
                              string_of_list (string_of_arg) e2s ^ ")"
    | ObjAttr (e1, e2) -> "ObjAttr (" ^ string_of_expr e1 ^ "," ^
                                        string_of_expr e2 ^ ")"
    | Seq (e1, e2) -> "Seq (" ^ string_of_expr e1 ^ "," ^
                                string_of_expr e2 ^ ")"
    | LambdaAbs (ps, e) -> "LambdaAbs (" ^
                               string_of_list (string_of_param) ps ^ "," ^
                               string_of_expr e ^ ")"
    | LambdaApp (e1, e2s) -> "LambdaApp (" ^
                                string_of_expr e1 ^ "," ^
                                string_of_list (string_of_arg) e2s ^ ")"
    | NativeLambdaApp (f, is) -> "NativeLambdaApp (" ^
                                    string_of_ident f ^ "," ^
                                    string_of_list (string_of_ident) is ^ ")"
    | Assign (e1, e2) -> "Assign (" ^ string_of_expr e1 ^ "," ^
                                      string_of_expr e2 ^ ")"
    | SuperAssign (e1, e2) -> "SuperAssign (" ^ string_of_expr e1 ^ "," ^
                                                string_of_expr e2 ^ ")"
    | ArrayAssign (e1, e2, e3) -> "ArrayAssign (" ^ string_of_expr e1 ^ "," ^
                                                    string_of_expr e2 ^ "," ^
                                                    string_of_expr e3 ^ ")"
    | ArraySuperAssign (e1, e2, e3) -> "ArraySuperAssign (" ^
                                          string_of_expr e1 ^ "," ^
                                          string_of_expr e2 ^ "," ^
                                          string_of_expr e3 ^ ")"
    | ObjAttrAssign (e1, e2, e3) -> "Assign (" ^ string_of_expr e1 ^ "," ^
                                                 string_of_expr e2 ^ "," ^
                                                 string_of_expr e3 ^ ")"
    | If (e1, e2, e3) -> "If (" ^ string_of_expr e1 ^ "," ^
                                  string_of_expr e2 ^ "," ^
                                  string_of_expr e3 ^ ")"
    | While (e1, e2) -> "While (" ^ string_of_expr e1 ^ "," ^
                                    string_of_expr e2 ^ ")"
    | Break -> "Break"
    | Next -> "Next"
    | Error -> "Error"

    | Tick (t, e) -> "Tick (" ^ string_of_tick t ^
                                string_of_expr e ^ ")"

