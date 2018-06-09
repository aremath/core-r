
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
type env = { elist : memref list }

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

type stack = { slist : slot list }

(* Frame *)
type frame =
  { fmap: memref Ident_Map.t }

(* Heap *)
type heapobj =
    FrameObj of frame
  | PromiseObj of expr * env
  | DataObj of value * attribute list

type heap =
  { hmap : heapobj MemRef_Map.t
  ; next_mem : memref }

(* Execution state *)
type state =
  { stack : stack
  ; heap : heap
  ; ident_count : int }

(* Utility functions *)

(* Memory references *)
let mem_of_int : int -> memref =
  fun addr ->
    {R.addr = addr}

let incr_mem : memref -> memref =
  fun mem ->
    {mem with R.addr = mem.R.addr + 1}


(* Fresh identifier *)
let fresh_ident : state -> ident * state =
  fun state ->
    let count2 = state.ident_count + 1 in
      ( { R.pkg = None
        ; R.name = "fs$" ^ string_of_int count2
        ; R.ident_tag = None }
      , {state with ident_count = count2})


(* Frame lookup *)
let frame_find_opt : ident -> frame -> memref option =
  fun id frame ->
    try
      Some (Ident_Map.find id frame.fmap)
    with
      Not_found -> None

let frame_add : ident -> memref -> frame -> frame =
  fun id mem frame ->
    {frame with fmap = Ident_Map.add id mem frame.fmap}


(* Stack operations *)
let stack_pop : stack -> (slot * stack) option =
  fun stack -> match stack.slist with
    | [] -> None
    | (slot :: tail) -> Some (slot, {stack with slist = tail})

let stack_pop_expr : stack -> (expr * env * stack) option =
  fun stack -> match stack_pop stack with
    | Some (ExprSlot (expr, env), stack2) -> Some (expr, env, stack2)
    | _ -> None

let stack_push : slot -> stack -> stack =
  fun slot stack ->
    {stack with slist = slot :: stack.slist}


(* Heap operations *)
let heap_find_opt : memref -> heap -> heapobj option =
  fun mem heap ->
    try
      Some (MemRef_Map.find mem heap.hmap)
    with
      Not_found -> None

let heap_insert : memref -> heapobj -> heap -> heap =
  fun mem obj heap ->
    {heap with hmap = MemRef_Map.add mem obj heap.hmap}

let heap_alloc : heapobj -> heap -> memref * heap =
  fun obj heap ->
    let used_mem = heap.next_mem in
      ( used_mem
      , {heap with hmap = MemRef_Map.add used_mem obj heap.hmap;
                   next_mem = incr_mem used_mem})

let heap_alloc_const : R.const -> heap -> (memref * heap) =
  fun const heap -> match const with
    | R.Num n -> heap_alloc (DataObj (NumArray [n], [])) heap
    | R.Str s -> heap_alloc (DataObj (StrArray [s], [])) heap


(* Environment operations *)
let env_pop : env -> (memref * env) option =
  fun env -> match env.elist with
    | [] -> None
    | (mem :: tail) -> Some (mem, {env with elist = tail})

let env_push : memref -> env -> env =
  fun mem env ->
    {env with elist = mem :: env.elist}

let rec env_find_opt : ident -> env -> heap -> memref option =
  fun id env heap -> match env_pop env with
    | None -> None
    | Some (mem, env2) -> match heap_find_opt mem heap with
      | Some (FrameObj frame) -> (match frame_find_opt id frame with
        | None -> env_find_opt id env2 heap
        | Some mem2 -> Some mem2)
      | _ -> None


