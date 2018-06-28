open Support
open Langutils
open Rules
open Engine

open String
open List

let rec repeat : string -> int -> string =
  fun str n ->
    if n <= 0 then
      ""
    else if n == 1 then
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


let string_of_memref: memref -> string =
    fun mem ->
    "mem (" ^ string_of_int mem.R.addr ^ ")"

let string_of_env: env -> string =
  fun env ->
    let binds = IdentMap.bindings env.id_map in
    let bind_strs = map (fun (i, m) ->
           string_of_pair (i, m) (string_of_ident, string_of_memref)) binds in
    let pred_str = string_of_memref env.pred_mem in
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
    | Some b -> if b == 1 then "True" else "False"
    | None -> "NaBool"

let string_of_rvector: rvector -> string =
    function
    | IntVec i ->
        String.concat "," (map string_of_rint (Array.to_list i))
    | FloatVec f ->
        String.concat "," (map string_of_rfloat (Array.to_list f))
    | ComplexVec c ->
        String.concat "," (map string_of_rcomplex (Array.to_list c))
    | StrVec s ->
        String.concat "," (map string_of_rstring (Array.to_list s))
    | BoolVec b ->
        String.concat "," (map string_of_rbool (Array.to_list b))

let string_of_attributes: attributes -> string =
  fun attrs ->
    let strs = Hashtbl.fold (fun k v acc ->
       (string_of_pair (k, v) (string_of_rstring, string_of_memref)) :: acc)
                 attrs.rstr_map [] in
      "Attrs {" ^ (string_of_list_semicolon strs) ^ "}"

let string_of_value: value -> string =
  function
    | Vec v -> "[" ^ (string_of_rvector v) ^ "]"
    | RefArray ms ->
        "MEMS[" ^ (string_of_list_comma (map string_of_memref ms)) ^ "]"
    | FuncVal (params, expr, mem) -> let mem_str = string_of_memref mem in
        let params_strs = map string_of_param params in
        let expr_str = string_of_expr expr in
          "Function (env : " ^ mem_str ^ ") " ^
                   "[" ^ string_of_list_comma params_strs ^ "] " ^
                   "{" ^ expr_str ^ "}"
    | EnvVal e -> string_of_env e
    | ListVal l ->
        let list_strs = map (fun (rs, mem) ->
            string_of_pair (rs, mem)
                           (string_of_rstring, string_of_memref)) l in
          "List [" ^ string_of_list_comma list_strs ^ "]"
        

let string_of_heapobj: heapobj -> string = 
  function
    | PromiseObj (e, m) ->
        "Promise (env : " ^ string_of_memref m ^ ") " ^
                "{" ^ string_of_expr e ^ "}"
    | DataObj (v, a) ->
        "Data (" ^ string_of_value v ^ ") " ^
             "(" ^ string_of_attributes a ^ ")"

let string_of_heap: heap -> string =
  fun heap ->
    let binds = MemRefMap.bindings heap.mem_map in
    let strs = map (fun (k, v) ->
          string_of_pair (k, v) (string_of_memref, string_of_heapobj)) binds in
    let mod_strs = map (fun s -> tab4 ^ s) strs in
      "Heap (next : " ^ string_of_memref heap.next_mem ^ ")\n" ^
                        string_of_list_newline mod_strs

let string_of_slot: slot -> string =
    function
    | ReturnSlot m -> "Return (" ^ string_of_memref m ^ ")"
    | UpdateSlot m -> "Update (" ^ string_of_memref m ^ ")"
    | EvalSlot e -> "Evaluate (" ^ string_of_expr e ^ ")"
    | SeqSlot es -> "Seq [" ^ string_of_list_semicolon
                              (map string_of_expr es) ^ "]"
    | ArgsSlot args -> "Args [" ^ string_of_list_comma
                                  (map string_of_arg args) ^ "]"
    | AttrSlot (mopt, expopt) ->
      let mstr = begin match mopt with
        | Some m -> string_of_memref m
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
        | Some m -> string_of_memref m
        | None -> "no mem"
      end in
        "LoopSlot (" ^ e1str ^ "," ^ e2str ^ "," ^ mstr ^ ")"
    | BranchSlot (e1, e2) -> let e1str = string_of_expr e1 in
        let e2str = string_of_expr e2 in
        "Branch (" ^ e1str ^ "," ^ e2str ^ ")"

let string_of_frame: frame -> string =
  fun frame ->
    let slot_str = string_of_slot frame.slot in
    let env_mem_str = string_of_memref frame.env_mem in
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
    let env_str = string_of_memref state.global_env_mem in
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

let string_of_rule : rule -> string =
  fun rule -> match rule with
    | RuleForceP -> "ForceP"
    | RuleForceF -> "ForceF"
    | RuleGetF -> "GetF"
    | RuleInvF -> "InvF"
    | RuleNativeInvF -> "NativeInvF"

    | RuleConst -> "Const"
    | RuleFun -> "Fun"
    | RuleFind -> "Find"
    | RuleGetP -> "GetP"

    | RuleUpdate -> "Update"
    | RuleAssId -> "AssId"
    | RuleDAss -> "DAss"
    | RuleAssStr -> "AssStr"
    | RuleDAssStr -> "DAssStr"

    | RuleIfEval -> "IfEval"
    | RuleIfRet -> "IfRet"
    | RuleWhileEval -> "WhileEval"
    | RuleWhileCondTrue -> "WhileCondTrue"
    | RuleWhileCondFalse -> "WhileCondFalse"
    | RuleWhileBodyDone -> "WhileBodyDone"
    | RuleBreak -> "Break"
    | RuleNext -> "Next"

    | RuleSeq -> "Seq"

    | _ -> "Unknown"

let string_of_rule_list : rule list -> string =
  fun rules ->
    "[" ^ string_of_list_comma (map string_of_rule rules) ^ "]"

let string_of_hist : (rule list * state) -> string =
  fun (rules, state) ->
    bar60 ^ "\n" ^
    string_of_rule_list rules ^ "\n" ^
    string_of_state state ^ "\n" ^
    bar60 ^ ""

let string_of_passresult : passresult -> string =
  fun (comps, errs, incomps) ->
    "Complete" ^ "\n" ^
    string_of_list_newline (map string_of_hist comps) ^ "\n" ^
    "Errors" ^ "\n" ^
    string_of_list_newline (map string_of_hist errs) ^ "\n" ^
    "Incomplete" ^ "\n" ^
    string_of_list_newline (map string_of_hist incomps) ^ ""

let string_of_passresult_list : passresult list -> string =
  fun passes ->
    let strs = (map string_of_passresult passes) in
    let mods = map (fun s -> repeat "****" 10 ^
                             "\n" ^ s ^ "\n" ^
                             repeat "****" 10) strs in
      string_of_list_newline (mods)

