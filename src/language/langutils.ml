
open Annotations
open Syntax
open Smtsyntax
open Support

open String
open List

let rec repeat : string -> int -> string =
  fun str n ->
    if n <= 0 then
      ""
    else if n = 1 then
      str
    else
      str ^ repeat str (n - 1)

let tab2 = repeat " " 2
let tab4 = tab2 ^ tab2
let tab8 = tab4 ^ tab4
let bar20 = repeat "----" 5
let bar40 = let b = bar20 in b ^ b
let bar60 = bar20 ^ bar40
let bar80 = let b = bar40 in b ^ b

let string_of_pair : ('a * 'b) -> (('a -> string) * ('b -> string)) -> string =
  fun (a, b) (fa, fb) ->
    "(" ^ fa a ^ "," ^ fb b ^ ")"

let string_of_list_semicolon : string list -> string =
  fun strs -> String.concat ";" strs

let string_of_list_comma : string list -> string =
  fun strs -> String.concat "," strs

let string_of_list_newline : string list -> string =
  fun strs -> String.concat "\n" strs


let string_of_list : ('a -> string) -> 'a list -> string =
  fun f xs ->
    "[" ^ String.concat "," (List.map f xs) ^ "]"

let string_of_source : source -> string =
  fun src ->
    "source {file:" ^ src.file ^ ";" ^
            "line:" ^ string_of_int src.line ^ ";" ^
            "col:" ^ string_of_int src.col ^ "}"

let string_of_rstring : rstring -> string =
  fun rstr -> match rstr with
     | None -> "NA_character_"
     | Some str -> str

(* Language *)
let string_of_id : ident -> string =
  fun id -> match id.pkg with
    | None -> "ident {pkg:" ^ "_" ^ ";name:" ^ string_of_rstring id.name ^ "}"
    | Some p -> "ident {pkg:" ^ string_of_rstring p ^
                ";name:" ^ string_of_rstring id.name ^ "}"

let string_of_mem : memref -> string =
  fun mem ->
    "addr: " ^ string_of_int mem.addr

let string_of_numeric : numeric -> string =
  fun num -> match num with
    | Int (Some i)      -> "Int (" ^ string_of_int i ^ ")"
    | Int None          -> "Int (Na)"
    | Float (Some f)    -> "Float (" ^ string_of_float f ^ ")"
    | Float None        -> "Float (Na)"
    | Complex (Some c)  -> "Complex (" ^ string_of_float (c.Complex.re) ^ "," ^
                                 string_of_float (c.Complex.im) ^ ")"
    | Complex None      -> "Complex (Na)"
    
let string_of_const : const -> string =
  fun const -> match const with
    | Num n         -> "Num (" ^ string_of_numeric n ^ ")"
    | Str (Some s)  -> "Str (" ^ s ^ ")"
    | Str None      -> "Str (Na)"
    | Bool (Some b) -> "Bool (" ^ string_of_int b ^ ")"
    | Bool None     -> "Bool (Na)"
    | Nil           -> "Nil"

let rec string_of_param : param -> string =
  fun param -> match param with
    | VarParam -> "..."
    | Param i -> "Param (" ^ string_of_id i ^ ")"
    | Default (i, e) -> "Default (" ^ string_of_id i ^ "," ^
                                      string_of_expr e ^ ")"

and string_of_arg : arg -> string =
  fun arg -> match arg with
    | VarArg -> "..."
    | Arg e -> "Arg (" ^ string_of_expr e ^ ")"
    | Named (i, e) -> "Named (" ^ string_of_id i ^ "," ^
                                  string_of_expr e ^ ")"

and string_of_tick : tick -> string =
  fun tick ->
    "tick {info:" ^ "_" ^ "}"

and string_of_expr : expr -> string =
  fun expr -> match expr with
    | Ident i -> "Ident (" ^ string_of_id i ^ ")"
    | MemRef m -> "MemRef (" ^ string_of_mem m ^ ")"
    | Const c -> "Const (" ^ string_of_const c ^ ")"
    | Seq es -> "Seq (" ^ string_of_list (string_of_expr) es ^ ")"
    | LambdaAbs (ps, e) -> "LambdaAbs (" ^
                               string_of_list (string_of_param) ps ^ "," ^
                               string_of_expr e ^ ")"
    | LambdaApp (e1, e2s) -> "LambdaApp (" ^
                                string_of_expr e1 ^ "," ^
                                string_of_list (string_of_arg) e2s ^ ")"
    | NativeLambdaApp (f, is) -> "NativeLambdaApp (" ^
                                    string_of_id f ^ "," ^
                                    string_of_list (string_of_id) is ^ ")"
    | Assign (e1, e2) -> "Assign (" ^ string_of_expr e1 ^ "," ^
                                      string_of_expr e2 ^ ")"
    | SuperAssign (e1, e2) -> "SuperAssign (" ^ string_of_expr e1 ^ "," ^
                                                string_of_expr e2 ^ ")"
    | If (e1, e2, e3) -> "If (" ^ string_of_expr e1 ^ "," ^
                                  string_of_expr e2 ^ "," ^
                                  string_of_expr e3 ^ ")"
    | While (e1, e2) -> "While (" ^ string_of_expr e1 ^ "," ^
                                    string_of_expr e2 ^ ")"
    | Break -> "Break"
    | Next -> "Next"
    | Return e -> "Return (" ^ string_of_expr e ^ ")"
    | Error -> "Error"

    | Tick (t, e) -> "Tick (" ^ string_of_tick t ^
                                string_of_expr e ^ ")"


(* SMT *)
let string_of_smtvar : smtvar -> string =
  fun var -> var

let string_of_smtconst : smtconst -> string =
  fun const -> const

let rec string_of_smtsort : smtsort -> string =
  fun sort ->
    match sort with
    | SortInt -> "SortInt"
    | SortFloat -> "SortFloat"
    | SortDouble -> "SortDouble"
    | SortBool -> "SortBool"
    | SortVar (v, ss) ->
        "SortVar (" ^ string_of_smtvar v ^ "," ^
                      string_of_list_comma (map string_of_smtsort ss) ^ ")"

let rec string_of_smtexpr : smtexpr -> string =
  fun smtexpr ->
    match smtexpr with
    | SmtVar v -> "Var (" ^ string_of_smtvar v ^ ")"
    | SmtConst c -> "Const (" ^ string_of_smtconst c ^ ")"

    | SmtGt (e1, e2) ->
        "Gt (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"

    | SmtGe (e1, e2) ->
        "Ge (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtLt (e1, e2) ->
        "Lt (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtLe (e1, e2) ->
        "Le (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtEq (e1, e2) ->
        "Eq (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtNeq (e1, e2) ->
        "Neq (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"

    | SmtAnd (e1, e2) ->
        "And (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtOr (e1, e2) ->
        "Or (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtNeg (e1) ->
        "Neg (" ^ string_of_smtexpr e1 ^ ")"
    | SmtImp (e1, e2) ->
        "Imp (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtIff (e1, e2) ->
        "SmtIff (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"

    | SmtPlus (e1, e2) ->
        "Plus (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtSub (e1, e2) ->
        "Sub (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtMult (e1, e2) ->
        "Mult (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtDiv (e1, e2) ->
        "Div (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtExp (e1, e2) ->
        "Exp (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtMod (e1, e2) ->
        "Mod (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"

    | SmtArrGet (e1, e2) ->
        "ArrGet (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"
    | SmtArrSet (e1, e2) ->
        "ArrSet (" ^ string_of_smtexpr e1 ^ "," ^ string_of_smtexpr e2 ^ ")"

    | SmtFunApp (f, es) ->
        "FunApp (" ^ string_of_smtvar f ^ "," ^
                     string_of_list_comma (map string_of_smtexpr es) ^ ")"
    | SmtLet (bs, e) ->
        "Let (" ^ string_of_list_comma
                  (map (fun (v, e) ->
                    string_of_pair
                    (v, e) (string_of_smtvar, string_of_smtexpr)) bs) ^ "," ^
                  string_of_smtexpr e ^ ")"

    | SmtForAll (bs, e) ->
        "ForAll (" ^ string_of_list_comma
                      (map (fun (v, s) ->
                        string_of_pair (v, s)
                          (string_of_smtvar, string_of_smtsort)) bs) ^ "," ^
                     string_of_smtexpr e ^ ")"

    | SmtExists (bs, e) ->
        "Exists (" ^ string_of_list_comma
                      (map (fun (v, s) ->
                        string_of_pair (v, s)
                          (string_of_smtvar, string_of_smtsort)) bs) ^ "," ^
                     string_of_smtexpr e ^ ")"



let string_of_env: env -> string =
  fun env ->
    let binds = IdentMap.bindings env.id_map in
    let bind_strs = map (fun (i, m) ->
           string_of_pair (i, m) (string_of_id, string_of_mem)) binds in
    let pred_str = string_of_mem env.pred_mem in
        "Env (pred : " ^ pred_str ^ ") " ^
            "{" ^ (string_of_list_semicolon bind_strs) ^ "}"

let string_of_rstring: rstring -> string =
    function
    | Some s -> "\"" ^ s ^ "\""
    | None -> "NaString"

let string_of_rint: rint -> string =
    function
    | Some i -> (string_of_int i)
    | None -> "NaInt"

let string_of_rfloat: rfloat -> string =
    function
    | Some f -> (string_of_float f)
    | None -> "NaFloat"

let string_of_rcomplex: rcomplex -> string =
    function
    | Some c -> "Complex (" ^ (string_of_float c.Complex.re) ^ "," ^
        (string_of_float c.Complex.im) ^ ")"
    | None -> "NaComplex"

let string_of_rbool: rbool -> string =
    function
    | Some b -> if b = 0 then "False" else "True"
    | None -> "NaBool"

let string_of_rtype : rtype -> string =
  fun ty -> match ty with
    | RBool -> "RBool"
    | RInt -> "RInt"
    | RFloat -> "RFloat"
    | RComplex -> "RComplex"
    | RString -> "RString"

let string_of_pathcons : pathcons -> string =
  fun path ->
    string_of_list_comma (map string_of_smtexpr path.path_list)

let string_of_rvector: rvector -> string =
    function
    | IntVec i ->
        string_of_list_comma (map string_of_rint (Array.to_list i))
    | FloatVec f ->
        string_of_list_comma (map string_of_rfloat (Array.to_list f))
    | ComplexVec c ->
        string_of_list_comma (map string_of_rcomplex (Array.to_list c))
    | StrVec s ->
        string_of_list_comma (map string_of_rstring (Array.to_list s))
    | BoolVec b ->
        string_of_list_comma (map string_of_rbool (Array.to_list b))
    | SymVec (i, t, p) ->
        "(" ^ string_of_smtvar i ^ ";" ^
              string_of_rtype t ^ ";" ^
              string_of_pathcons p ^ ")"

let string_of_attributes: attributes -> string =
  fun attrs ->
    let strs = Hashtbl.fold (fun k v acc ->
       (string_of_pair (k, v) (string_of_rstring, string_of_mem)) :: acc)
                 attrs.rstr_map [] in
      "Attrs {" ^ (string_of_list_semicolon strs) ^ "}"


let string_of_value: value -> string =
  function
    | Vec v -> "[" ^ (string_of_rvector v) ^ "]"
    | RefArray ms ->
        "MEMS[" ^ (string_of_list_comma (map string_of_mem ms)) ^ "]"
    | FuncVal (params, expr, mem) -> let mem_str = string_of_mem mem in
        let params_strs = map string_of_param params in
        let expr_str = string_of_expr expr in
          "Function (env : " ^ mem_str ^ ") " ^
                   "[" ^ string_of_list_comma params_strs ^ "] " ^
                   "{" ^ expr_str ^ "}"
    | EnvVal e -> string_of_env e
    (* | ListVal l ->
        let list_strs = map (fun mem -> string_of_mem mem) l in
          "List [" ^ string_of_list_comma list_strs ^ "]" *)

let string_of_heapobj: heapobj -> string = 
  function
    | PromiseObj (e, m) ->
        "Promise (env : " ^ string_of_mem m ^ ") " ^
                "{" ^ string_of_expr e ^ "}"
    | DataObj (v, a) ->
        "Data (" ^ string_of_value v ^ ") " ^
             "(" ^ string_of_attributes a ^ ")"

let string_of_heap: heap -> string =
  fun heap ->
    let binds = MemRefMap.bindings heap.mem_map in
    let strs = map (fun (k, v) ->
          string_of_pair (k, v) (string_of_mem, string_of_heapobj)) binds in
    let mod_strs = map (fun s -> tab4 ^ s) strs in
      "Heap (next : " ^ string_of_mem heap.next_mem ^ ")\n" ^
                        string_of_list_newline mod_strs

let string_of_slot: slot -> string =
    function
    | ReturnSlot m -> "Return (" ^ string_of_mem m ^ ")"
    | UpdateSlot m -> "Update (" ^ string_of_mem m ^ ")"
    | EvalSlot e -> "Evaluate (" ^ string_of_expr e ^ ")"
    | SeqSlot es -> "Seq [" ^ string_of_list_semicolon
                              (map string_of_expr es) ^ "]"
    | ArgsSlot args -> "Args [" ^ string_of_list_comma
                                  (map string_of_arg args) ^ "]"
    | AttrSlot (mopt, expopt) ->
      let mstr = begin match mopt with
        | Some m -> string_of_mem m
        | None -> "no mem"
      end in
      let expstr = begin match expopt with
        | Some e -> string_of_expr e
        | None -> "no expr"
      end in
        "AttrSlot (" ^ mstr ^ "," ^ expstr ^ ")"
    | LoopSlot (e1, e2, mopt) ->
      let e1str = string_of_expr e1 in
      let e2str = string_of_expr e2 in
      let mstr = begin match mopt with
        | Some m -> string_of_mem m
        | None -> "no mem"
      end in
        "LoopSlot (" ^ e1str ^ "," ^ e2str ^ "," ^ mstr ^ ")"
    | BranchSlot (e1, e2) -> let e1str = string_of_expr e1 in
        let e2str = string_of_expr e2 in
        "Branch (" ^ e1str ^ "," ^ e2str ^ ")"

    | AssignSlot id ->
        "AssignSlot (" ^ string_of_id id ^ ")"
    | SupAssignSlot id ->
        "SupAssignSlot (" ^ string_of_id id ^ ")"
    | LambdaASlot (f_mem_opt, da_mems, a_opt, args) ->
        let f_str = match f_mem_opt with
                    | Some mem -> string_of_mem mem
                    | None -> "None" in
        let a_str = match a_opt with
                    | Some arg -> string_of_arg arg
                    | None -> "None" in
          "LambdaASlot (" ^ f_str ^ "," ^
                      "[" ^ string_of_list_comma
                            (map (fun p -> string_of_pair p
                                           (string_of_arg, string_of_mem))
                                 da_mems) ^ "]," ^
                      a_str ^ "," ^
                      "[[" ^
                        string_of_list_comma (map string_of_arg args) ^
                        "]]"
    | LambdaBSlot mem ->
          "LambdaBSlot (" ^ string_of_mem mem ^ ")"

let string_of_frame: frame -> string =
  fun frame ->
    let slot_str = string_of_slot frame.slot in
    let env_mem_str = string_of_mem frame.env_mem in
      "Frame (env : " ^ env_mem_str ^ ")\n" ^
              tab8 ^ tab2 ^ "" ^ slot_str ^ ""

let string_of_stack: stack -> string =
  fun s ->
    let frame_strs = List.map string_of_frame s.frame_list in
    let mod_strs = map (fun s -> tab4 ^ s) frame_strs in
      "Stack\n" ^ string_of_list_newline mod_strs

let string_of_state: state -> string =
  fun state ->
    let stack_str = string_of_stack state.stack in
    let heap_str = string_of_heap state.heap in
    let env_str = string_of_mem state.global_env_mem in
    (* let count = string_of_int state.fresh_count in *)
      "State " ^ "(global: " ^ env_str ^ ") " ^
                 "(" ^ string_of_int state.unique ^ ") "^
                 "(pred : " ^ string_of_int state.pred_unique ^ ")" ^
                 "\n" ^
      "\n" ^  tab2 ^ stack_str ^ "\n" ^
      "\n" ^ tab2 ^ heap_str ^ ""

let string_of_state_list : state list -> string =
  fun states ->
    string_of_list_newline (map string_of_state states)
