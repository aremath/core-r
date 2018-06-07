
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
    | Na -> "Na"
    | Int i -> "Int (" ^ string_of_int i ^ ")"
    | Float f -> "Float (" ^ string_of_float f ^ ")"
    | Complex (r, i) -> "Complex (" ^ string_of_float r ^ "," ^
                                      string_of_float i ^ ")"
    
and string_of_const : const -> string =
  fun const -> match const with
    | Num n -> "Num (" ^ string_of_numeric n ^ ")"
    | Str s -> "Str (" ^ s ^ ")"

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
    | ArraySub (e1, e2) -> "ArraySub (" ^ string_of_expr e1 ^ "," ^
                                          string_of_expr e2 ^ ")"
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
    | For (i, e1, e2) -> "For (" ^ string_of_ident i ^ "," ^
                                   string_of_expr e1 ^ "," ^
                                   string_of_expr e2 ^ ")"
    | Break -> "Break"
    | Next -> "Next"
    | Error -> "Error"

    | Tick (t, e) -> "Tick (" ^ string_of_tick t ^
                                string_of_expr e ^ ")"

