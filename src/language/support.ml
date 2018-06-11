
module R = Syntax
module A = Annotations

(* Type aliases *)
type itag = A.itag
type ttag = A.ttag
type tick = A.ttag R.tick
type memref = R.memref
type numeric = R.numeric
type ident = itag R.ident
type param = (itag, ttag) R.param
type arg = (itag, ttag) R.arg
type expr = (itag, ttag) R.expr

(* Memory reference Map *)
module MemRef = struct
  type t = memref

  let compare : t -> t -> int =
    fun a b ->
      compare a.R.addr b.R.addr
end

module MemRef_Map = Map.Make (MemRef)

(* Identifier Map *)
module Ident = struct
  type t = ident

  let compare : t -> t -> int =
    fun a b ->
      compare a.R.name b.R.name
end

module Ident_Map = Map.Make (Ident)

(* Environment *)
type env = { env_list : memref list }

(* Values *)
type value =
    NumArray of numeric list
  | StrArray of string list
  | RefArray of memref list
  | FuncVal of param list * expr * env

type attribute = unit

(* Stack *)
type slot =
    ExprSlot of expr * env
  | UpdateSlot of memref
  | WhileSlot of expr
  | ForSlot of unit
  | IfSlot of expr * expr
  | RepeatSlot
  | ArraySubSlot of memref option *
                    memref list * 
                    (ident * memref) list *
                    ident option *
                    arg list *
                    env

type stack = { stack_list : slot list }

(* Frame *)
type frame = { frame_map: memref Ident_Map.t }

(* Heap *)
type heapobj =
    FrameObj of frame
  | PromiseObj of expr * env
  | DataObj of value * attribute list

type heap =
  { heap_map : heapobj MemRef_Map.t;
    next_mem : memref }

(* Execution state *)
type state =
  { stack : stack;
    heap : heap;
    ident_count : int }


(* Utility functions *)

(* Syntax tree utilities *)

let id_expr_of_arg : arg -> (ident option * expr) option =
  fun arg -> match arg with
    | VarArg -> None
    | Arg expr -> Some (None, expr)
    | Named (id, expr) -> Some (Some id, expr)


(* Memory references *)

let mem_of_int : int -> memref =
  fun addr ->
    { R.addr = addr }

let incr_mem : memref -> memref =
  fun mem ->
    { mem with R.addr = mem.R.addr + 1 }


(* Fresh identifier *)
let default_id : ident =
  { R.pkg = None;
    R.name = "";
    R.ident_tag = None }

let fresh_id : state -> ident * state =
  fun state ->
    let count2 = state.ident_count + 1 in
    let name2 = "fs$" ^ string_of_int count2 in
      ({ default_id with R.name = name2 },
       { state with ident_count = count2 })


(* Frame lookup *)

let frame_empty : frame =
  { frame_map = Ident_Map.empty }

let frame_find : ident -> frame -> memref option =
  fun id frame ->
    try
      Some (Ident_Map.find id frame.frame_map)
    with
      Not_found -> None

let frame_add : ident -> memref -> frame -> frame =
  fun id mem frame ->
    { frame with frame_map = Ident_Map.add id mem frame.frame_map }


(* Stack operations *)

let stack_empty : stack =
  { stack_list = [] }

let stack_pop : stack -> (slot * stack) option =
  fun stack -> match stack.stack_list with
    | [] -> None
    | (slot :: tail) -> Some (slot, { stack with stack_list = tail })

let stack_pop_2 : stack -> (slot * slot * stack) option =
  fun stack -> match stack.stack_list with
    | (slot1 :: slot2 :: tail) ->
        Some (slot1, slot2, { stack with stack_list = tail })
    | _ -> None

let stack_pop_expr : stack -> (expr * env * stack) option =
  fun stack -> match stack_pop stack with
    | Some (ExprSlot (expr, env), stack2) -> Some (expr, env, stack2)
    | _ -> None

let stack_push : slot -> stack -> stack =
  fun slot stack ->
    { stack with stack_list = slot :: stack.stack_list }


(* Heap operations *)

let heap_empty : heap =
  { heap_map = MemRef_Map.empty;
    next_mem = mem_of_int 1 }

let heap_find : memref -> heap -> heapobj option =
  fun mem heap ->
    try
      Some (MemRef_Map.find mem heap.heap_map)
    with
      Not_found -> None

let heap_add : memref -> heapobj -> heap -> heap =
  fun mem obj heap ->
    { heap with heap_map = MemRef_Map.add mem obj heap.heap_map }

let heap_alloc : heapobj -> heap -> memref * heap =
  fun obj heap ->
    let used_mem = heap.next_mem in
      (used_mem,
       { heap with heap_map = MemRef_Map.add used_mem obj heap.heap_map;
                   next_mem = incr_mem used_mem })

let heap_alloc_const : R.const -> heap -> (memref * heap) =
  fun const heap -> match const with
    | R.Num n -> heap_alloc (DataObj (NumArray [n], [])) heap
    | R.Str s -> heap_alloc (DataObj (StrArray [s], [])) heap


(* Environment operations *)

let env_empty : env =
  { env_list = [] }

let env_pop : env -> (memref * env) option =
  fun env -> match env.env_list with
    | [] -> None
    | (f_mem :: tail) -> Some (f_mem, { env with env_list = tail })

let env_push : memref -> env -> env =
  fun f_mem env ->
    { env with env_list = f_mem :: env.env_list }

(* Pop the top-level frame and its memory reference on the heap *)
let env_pop_frame : env -> heap -> (memref * frame * env) option =
  fun env heap -> match env_pop env with
    | None -> None
    | Some (f_mem, env2) -> match heap_find f_mem heap with
      | Some (FrameObj frame) -> Some (f_mem, frame, env2)
      | _ -> None
  
(* Add a mapping to the frame at the top level.
   Do not push new frames if the memory reference is wrong. *)
let env_add_map : ident -> memref -> env -> heap -> (env * heap) option =
  fun id mem env heap -> match env_pop_frame env heap with
    | None -> None
    | Some (f_mem, frame, _) ->
        let f_obj = FrameObj (frame_add id mem frame) in
        let heap2 = heap_add f_mem f_obj heap in
          Some (env, heap2)

(* Allocate a new thunk expression.
   Do not push new frames into env if mapping is wrong. *)
let env_add_map_thunk : ident -> expr -> env -> heap -> (env * heap) option =
  fun id expr env heap ->
    let p_obj = PromiseObj (expr, env) in
    let (mem, heap2) = heap_alloc p_obj heap in
      env_add_map id mem env heap2

let rec env_find : ident -> env -> heap -> memref option =
  fun id env heap -> match env_pop_frame env heap with
    | None -> None
    | Some (f_mem, frame, env2) -> match frame_find id frame with
      | None -> env_find id env2 heap
      | Some mem -> Some mem
  

