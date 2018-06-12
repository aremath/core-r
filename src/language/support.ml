
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
type env = { env_map : memref Ident_Map.t }

(* Values *)
type value =
    NumArray of numeric list
  | StrArray of (string option) list
  | BoolArray of (int option) list
  | RefArray of memref list
  | FuncVal of param list * expr * env

type attribute = unit

(* Stack *)
type slot =
    ReturnSlot of memref
  | EvalSlot of expr
  | SeqSlot of expr list
  | ArgsSlot of arg list
  | UpdateSlot of memref
  | WhileSlot of expr
  | ForSlot of unit
  | IfSlot of expr * expr
  | RepeatSlot
  | ArraySubSlot of memref option *  memref list * (ident * memref) list *
                    ident option * arg list

type frame =
  { frame_env : env;
    slot_list : slot list }

type stack = { frame_list : frame list }


(* Heap *)
type heapobj =
    PromiseObj of expr * env
  | DataObj of value * attribute list

type heap =
  { heap_map : heapobj MemRef_Map.t;
    next_mem : memref }

(* Execution state *)
type state =
  { state_stack : stack;
    state_heap : heap;
    state_env : env;
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

let mem_incr : memref -> memref =
  fun mem ->
    { mem with R.addr = mem.R.addr + 1 }


(* Fresh identifier *)
let id_default : ident =
  { R.pkg = None;
    R.name = "";
    R.ident_tag = None }

let id_of_string : string -> ident =
  fun name ->
    { id_default with R.name = name }

let id_fresh : state -> ident * state =
  fun state ->
    let count2 = state.ident_count + 1 in
    let name2 = "fs$" ^ string_of_int count2 in
      (id_of_string name2, { state with ident_count = count2 })


(* Environment lookup *)
let env_empty : env =
  { env_map = Ident_Map.empty }

let env_find : ident -> env -> memref option =
  fun id env ->
    try
      Some (Ident_Map.find id env.env_map)
    with
      Not_found -> None

let env_add : ident -> memref -> env -> env =
  fun id mem env ->
    { env with env_map = Ident_Map.add id mem env.env_map }


(* Frame operations *)
let frame_empty : frame =
  { frame_env = env_empty;
    slot_list = [] }

let frame_pop : frame -> (slot * frame) option =
  fun frame -> match frame.slot_list with
    | [] -> None
    | (slot :: tail) -> Some (slot, { frame with slot_list = tail })

let frame_pop_2 : frame -> (slot * slot * frame) option =
  fun frame -> match frame_pop frame with
    | None -> None
    | Some (slot1, frame2) -> match frame_pop frame2 with
      | None -> None
      | Some (slot2, frame3) -> Some (slot1, slot2, frame3)

let frame_push : slot -> frame -> frame =
  fun slot frame ->
    { frame with slot_list = slot :: frame.slot_list }

let frame_push_2 : slot -> slot -> frame -> frame =
  fun slot1 slot2 frame ->
    frame_push slot1 (frame_push slot2 frame)


(* Stack operations *)
let stack_empty : stack =
  { frame_list = [] }

let stack_pop : stack -> (frame * stack) option =
  fun stack -> match stack.frame_list with
    | [] -> None
    | (frame :: tail) -> Some (frame, { stack with frame_list = tail })

let stack_pop_slot : stack -> (slot * frame * stack) option =
  fun stack -> match stack_pop stack with
    | None -> None
    | Some (frame, stack2) -> match frame_pop frame with
      | None -> None
      | Some (slot, frame2) -> Some (slot, frame2, stack2)

let stack_pop_slot_2 : stack -> (slot * slot * frame * stack) option =
  fun stack -> match stack_pop stack with
    | None -> None
    | Some (frame, stack2) -> match frame_pop_2 frame with
      | None -> None
      | Some (slot1, slot2, frame2) -> Some (slot1, slot2, frame2, stack2)

let stack_push : frame -> stack -> stack =
  fun frame stack ->
    { stack with frame_list = frame :: stack.frame_list }


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

let rec heap_find_deep : memref -> heap -> (memref * heapobj) option =
  fun mem heap -> match heap_find mem heap with
    | None -> None
    | Some (PromiseObj (MemRef mem2, _)) -> heap_find_deep mem2 heap
    | Some obj -> Some (mem, obj)

let heap_add : memref -> heapobj -> heap -> heap =
  fun mem obj heap ->
    { heap with heap_map = MemRef_Map.add mem obj heap.heap_map }

let heap_alloc : heapobj -> heap -> memref * heap =
  fun obj heap ->
    let used_mem = heap.next_mem in
      (used_mem,
       { heap with heap_map = MemRef_Map.add used_mem obj heap.heap_map;
                   next_mem = mem_incr used_mem })

let heap_alloc_const : R.const -> heap -> (memref * heap) =
  fun const heap -> match const with
    | R.Num n -> heap_alloc (DataObj (NumArray [n], [])) heap
    | R.Str s -> heap_alloc (DataObj (StrArray [s], [])) heap
    | R.Bool b -> heap_alloc (DataObj (BoolArray [b], [])) heap



