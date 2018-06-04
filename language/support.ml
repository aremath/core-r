
module R = Syntax

(* Type aliases *)
type tag = unit
type memref = R.memref
type numeric = R.numeric
type ident = tag R.ident
type param = tag R.param
type arg = tag R.arg
type expr = tag R.expr

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

type stack =
  slot list

(* Frame *)
type frame = memref Ident_Map.t

(* Heap *)
type heapobj =
    FrameObj of frame
  | PromiseObj of expr * env
  | DataObj of value * attribute list

type heap = heapobj MemRef_Map.t

(* Utility functions *)

(* Environment operations *)
let env_top : env -> memref option =
  fun env -> match env with
    | [] -> None
    | (hd :: _) -> Some hd

let env_pop : env -> env option =
  fun env -> match env with
    | [] -> None
    | (_ :: tl) -> Some tl

let env_push : memref -> env -> env =
  fun mem env ->
    mem :: env

(* Stack operations *)
let stack_top : stack -> slot option =
  fun stack -> match stack with
    | [] -> None
    | (hd :: _ ) -> Some hd

let stack_pop : stack -> stack option =
  fun stack -> match stack with
    | [] -> None
    | (_ :: tl) -> Some tl

let stack_push : slot -> stack -> stack =
  fun slot stack ->
    slot :: stack

(* Heap operations *)
let heap_find_opt : memref -> heap -> heapobj option =
  fun mem heap ->
    try
      Some (MemRef_Map.find mem heap)
    with
      Not_found -> None

let heap_add : memref -> heapobj -> heap -> heap =
  fun mem obj heap ->
    MemRef_Map.add mem obj heap


