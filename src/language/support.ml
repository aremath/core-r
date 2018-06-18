
module R = Syntax
module A = Annotations

(* Type aliases *)
type tag = A.tag
type annot = A.annot
type tick = A.annot R.tick
type memref = R.memref
type numeric = R.numeric
type ident = tag R.ident
type param = (tag, annot) R.param
type arg = (tag, annot) R.arg
type expr = (tag, annot) R.expr

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
type env =
  { mem_map : memref Ident_Map.t;
    pred_mem : memref option }

(* Values *)
type value =
    IntArray of R.rint array
  | FloatArray of R.rfloat array
  | ComplexArray of R.rcomplex array
  | StrArray of R.rstring array
  | BoolArray of R.rbool array
  | RefArray of memref list
  | FuncVal of param list * expr * memref

type attribute = unit

(* Stack *)
type slot =
    ReturnSlot of memref
  | EvalSlot of expr
  | SeqSlot of expr list
  | ArgsSlot of arg list
  | UpdateSlot of memref
  | LoopSlot of expr * expr * memref option (* body's return value *)
  | IfSlot of expr * expr
  | ArraySubSlot of memref option *  memref list * (ident * memref) list *
                    ident option * arg list

type frame =
  { env_mem : memref;
    slot : slot }

type stack =
  { frame_list : frame list }


(* Heap *)
type heapobj =
    PromiseObj of expr * memref
  | DataObj of value * attribute list
  | EnvObj of env

type heap =
  { hobj_map : heapobj MemRef_Map.t;
    next_mem : memref }

(* Execution state *)
type state =
  { stack : stack;
    heap : heap;
    global_env_mem : memref;
    fresh_count : int }


(* Utility functions *)

(* Syntax tree utilities *)

let id_expr_of_arg : arg -> (ident option * expr) option =
  fun arg -> match arg with
    | R.VarArg -> None
    | R.Arg expr -> Some (None, expr)
    | R.Named (id, expr) -> Some (Some id, expr)


(* Memory references *)
let mem_of_int : int -> memref =
  fun addr ->
    { R.addr = addr }

let mem_incr : memref -> memref =
  fun mem ->
    { mem with R.addr = mem.R.addr + 1 }

let mem_null : memref =
  mem_of_int 0


(* Fresh identifier *)
let id_default : ident =
  { R.pkg = None;
    R.name = "";
    R.tag = None }

let id_of_string : string -> ident =
  fun name ->
    { id_default with R.name = name }

let id_fresh : state -> ident * state =
  fun state ->
    let count2 = state.fresh_count + 1 in
    let name = "fs$" ^ string_of_int count2 in
      (id_of_string name, { state with fresh_count = count2 })

let rec id_fresh_list : int -> state -> (ident list) * state =
  fun n state ->
    if n < 1 then
      ([], state)
    else
      let (id, state2) = id_fresh state in
      let (ids_tl, state3) = id_fresh_list (n - 1) state2 in
        (id :: ids_tl, state3)


(* Frame operations *)
let frame_default : frame =
  { env_mem = mem_null ;
    slot = ReturnSlot mem_null }


(* Stack operations *)
let stack_empty : stack =
  { frame_list = [] }

let stack_pop : stack -> (frame * stack) option =
  fun stack -> match stack.frame_list with
    | [] -> None
    | (frame :: frames_tl) ->
        Some (frame, { stack with frame_list = frames_tl })

let stack_pop_v : stack -> (slot * memref * stack) option =
  fun stack -> match stack_pop stack with
    | None -> None
    | Some (frame, stack2) -> Some (frame.slot, frame.env_mem, stack2)

let stack_pop_v2 : stack -> (slot * memref * slot * memref * stack) option =
  fun stack -> match stack_pop_v stack with
    | None -> None
    | Some (slot1, env_mem1, stack2) -> match stack_pop_v stack2 with
      | None -> None
      | Some (slot2, env_mem2, stack3) ->
          Some (slot1, env_mem1, slot2, env_mem2, stack3)

let stack_push : frame -> stack -> stack =
  fun frame stack ->
    { stack with frame_list = frame :: stack.frame_list }


(* Heap operations *)
let heap_empty : heap =
  { hobj_map = MemRef_Map.empty;
    next_mem = mem_incr mem_null }

let heap_find : memref -> heap -> heapobj option =
  fun mem heap ->
    try
      Some (MemRef_Map.find mem heap.hobj_map)
    with
      Not_found -> None

let rec heap_find_deep : memref -> heap -> (memref * heapobj) option =
  fun mem heap -> match heap_find mem heap with
    | None -> None
    | Some (PromiseObj (R.MemRef mem2, _)) -> heap_find_deep mem2 heap
    | Some hobj -> Some (mem, hobj)

let heap_add : memref -> heapobj -> heap -> heap =
  fun mem hobj heap ->
    { heap with hobj_map = MemRef_Map.add mem hobj heap.hobj_map }

let heap_alloc : heapobj -> heap -> memref * heap =
  fun hobj heap ->
    let used_mem = heap.next_mem in
      (used_mem,
       { heap with hobj_map = MemRef_Map.add used_mem hobj heap.hobj_map;
                   next_mem = mem_incr used_mem })

let rec heap_alloc_list : heapobj list -> heap -> memref list * heap =
  fun hobjs heap -> match hobjs with
    | [] -> ([], heap)
    | (hobj :: hobjs_tl) ->
        let (mem, heap2) = heap_alloc hobj heap in
        let (mems_tl, heap3) = heap_alloc_list hobjs_tl heap2 in
          (mem :: mems_tl, heap3)

let heap_alloc_const : R.const -> heap -> (memref * heap) =
  fun const heap ->
    let arr = (match const with
                  R.Str s -> StrArray (Array.of_list [s])
                | R.Bool b -> BoolArray (Array.of_list [b])
                | R.Num (R.Int i) -> IntArray (Array.of_list [i])
                | R.Num (R.Float f) -> FloatArray (Array.of_list [f])
                | R.Num (R.Complex c) -> ComplexArray (Array.of_list [c])) in
    heap_alloc (DataObj (arr, [])) heap


(* Environment lookup *)
let env_empty : env =
  { mem_map = Ident_Map.empty;
    pred_mem = None }

let rec env_find : ident -> env -> heap -> memref option =
  fun id env heap ->
    try
      Some (Ident_Map.find id env.mem_map)
    with
      Not_found -> match env.pred_mem with
        | None -> None
        | Some env_mem2 -> match heap_find env_mem2 heap with
          | Some (EnvObj env2) -> env_find id env2 heap
          | _ -> None

let env_mem_find : ident -> memref -> heap -> memref option =
  fun id env_mem heap -> match heap_find env_mem heap with
    | Some (EnvObj env) -> env_find id env heap
    | _ -> None

let env_add : ident -> memref -> env -> env =
  fun id mem env ->
    { env with mem_map = Ident_Map.add id mem env.mem_map }

let env_mem_add : ident -> memref -> memref -> heap -> heap option =
  fun id mem env_mem heap -> match heap_find env_mem heap with
    | Some (EnvObj env) ->
        let env2 = env_add id mem env in
          Some (heap_add env_mem (EnvObj env2) heap)
    | _ -> None

let rec env_mem_add_list :
  (ident * memref) list -> memref -> heap -> heap option =
  fun binds env_mem heap -> match binds with
    | [] -> Some heap
    | ((id, mem) :: binds_tl) -> match env_mem_add id mem env_mem heap with
      | None -> None
      | Some heap2 -> env_mem_add_list binds_tl env_mem heap2

let env_nest : memref -> env =
  fun env_mem ->
    { env_empty with pred_mem = Some env_mem }


