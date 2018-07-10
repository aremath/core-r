open Support
open Langutils
open Rules
open Engine

open String
open List

let rec range : int -> int -> int list =
  fun low high ->
    if low > high then
      []
    else
      low :: range (low + 1) high

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

let string_of_list : ('a -> string) -> 'a list -> string =
  fun f xs ->
      "[" ^ String.concat "," (List.map f xs) ^ "]"

let string_of_rule : rule -> string =
  fun rule -> match rule with
    | ERuleIdent -> "Ident"
    | ERuleMemRef -> "MemRef"
    | ERuleConst -> "Const"
    | ERuleSeq -> "Seq"
    | ERuleLambdaAbs -> "LambdaAbs"
    | ERuleLambdaAppEval -> "LambdaAppEval"
    | ERuleLambdaAppFuncRet -> "LambdaAppFuncRet"
    | ERuleLambdaAppArgsEval -> "LambdaAppArgsEval"
    | ERuleLambdaAppArgsRet -> "LambdaAppArgsRet"
    | ERuleLambdaAppEnter -> "LambdaAppEnter"
    | ERuleLambdaAppComplete -> "LambdaAppComplete"
    | ERuleNativeLambdaApp -> "NativeLambdaApp"
    | ERuleAssignIdEval -> "AssignIdEval"
    | ERuleAssignStrEval -> "AssignStrEval"
    | ERuleAssignRet -> "AssignRet"
    | ERuleIfEval -> "IfEval"
    | ERuleIfRet -> "IfRet"
    | ERuleWhileEval -> "WhileEval"
    | ERuleWhileCondTrue -> "WhileCondTrue"
    | ERuleWhileCondFalse -> "WhileCondFalse"
    | ERuleWhileBodyDone -> "WhileBodyDone"
    | ERuleBreak -> "Break"
    | ERuleNext -> "Next"
    | ERuleReturn -> "Return"
    | ERuleDiscard -> "Discard"
    | ERuleBlank -> "Blank"


let string_of_rule_list : rule list -> string =
  fun rules ->
    "[" ^ string_of_list_comma (map string_of_rule rules) ^ "]"

let string_of_hist : (rule list * state) -> string =
  fun (rules, state) ->
    string_of_rule_list rules ^ "\n" ^
    string_of_state state ^ ""

let string_of_passresult : passresult -> string =
  fun (comps, errs, incomps) ->
    string_of_list_newline
      (map (fun c ->
            bar60 ^ "\n" ^
            "{Complete}:\n" ^ string_of_hist c ^ "\n" ^
            bar60) comps) ^ "\n" ^

    string_of_list_newline
      (map (fun c ->
            bar60 ^ "\n" ^
            "{Error}:\n" ^ string_of_hist c ^ "\n" ^
            bar60 ^ "") errs) ^ "\n" ^

    string_of_list_newline
      (map (fun c ->
            bar60 ^ "\n" ^
            "{Incomplete}:\n" ^ string_of_hist c ^ "\n" ^
            bar60 ^ "") incomps) ^ ""

let string_of_passresult_list : passresult list -> string =
  fun passes ->
    let strs = (map string_of_passresult passes) in
    let mods = map (fun (s, i) ->
                       "(" ^ string_of_int i ^ ") " ^
                       repeat "####" 10 ^
                       "\n" ^ s ^ "\n" ^
                       repeat "^^^^" 10)
                   (combine strs (range 1 (length strs))) in
      string_of_list_newline mods


let string_of_passresult_list_first_complete : passresult list -> string =
  fun passes ->
    match filter (fun (c, e, i) -> length c > 0) passes with
    | [] -> "No completes yet"
    | (p :: _) -> string_of_passresult p


let string_of_value_attr_opt_pair : (value * attributes) option -> string =
  fun res -> match res with
    | None -> "No result yet, run for higher values of n"
    | Some (v, a) ->
        "value: " ^ string_of_value v ^ "\n" ^
        "attrs: " ^ string_of_attributes a ^ ""



