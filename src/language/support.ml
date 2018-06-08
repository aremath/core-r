
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
type env = memref list

(* Values *)
type value =
    NumArray of numeric list
  | StrArray of string list
  | RefArray of memref list
  | FuncVal of param list * expr * env

type attribute = unit

(* Stack *)
type slot =
  { expr : expr
  ; env : env }

type stack = slot list

(* Frame *)
type frame = memref Ident_Map.t

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

(* Fresh identifier *)
let fresh_ident : state -> ident * state =
  fun st ->
    let count' = st.ident_count + 1 in
      ( {R.pkg = None; R.name = "fs$" ^ string_of_int count'; R.tag = None}
      , {st with ident_count = count'})


(* Environment operations *)
let env_pop : env -> (memref * env) option =
  fun env -> match env with
    | [] -> None
    | (mem :: env') -> Some (mem, env')

let env_push : memref -> env -> env =
  fun mem env ->
    mem :: env

(* Stack operations *)
let stack_pop : stack -> (slot * stack) option =
  fun stack -> match stack with
    | [] -> None
    | (slot :: env') -> Some (slot, env')

let stack_pop_v : stack -> (expr * env * stack) option =
  fun stack -> match stack_pop stack with
    | None -> None
    | Some (slot, stack') -> Some (slot.expr, slot.env, stack')

let stack_push : slot -> stack -> stack =
  fun slot stack ->
    slot :: stack

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

let heap_alloc : heapobj -> heap -> heap =
  fun obj heap ->
    {hmap = MemRef_Map.add (heap.next_mem) obj heap.hmap;
     next_mem = {R.addr = heap.next_mem.R.addr + 1}}

(*
let heap_copy : memref -> state -> (memref * state) option =
  fun mem st -> match heap_find_opt mem st.heap with
    | None -> None
    | Some v ->
        let (mem', state') = fresh_memref st in
          Some (mem', {state' with heap = heap_add mem' v state'.heap})

*)

