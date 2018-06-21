
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
type rint = R.rint
type rfloat = R.rfloat
type rcomplex = R.rcomplex
type rstring = R.rstring
type rbool = R.rbool


(* Memory reference Map *)
module MemRef = struct
  type t = memref

  let compare : t -> t -> int =
    fun a b ->
      compare a.R.addr b.R.addr
end

module MemRefMap = Map.Make(MemRef)


(* RString Map *)
module RString = struct
  type t = rstring

  let compare : t -> t -> int =
    fun a b ->
      compare a b
end

module RStringMap = Map.Make(RString)


(* Identifier Map *)
module Ident = struct
  type t = ident

  let compare : t -> t -> int =
    fun a b ->
      compare (a.R.pkg, a.R.name) (b.R.pkg, b.R.name)
end

module IdentMap = Map.Make(Ident)


(* Environment *)
type env =
  { id_map : memref IdentMap.t;
    pred_mem : memref }

(* Values *)
type rvector =
  | IntVec of rint array
  | FloatVec of rfloat array
  | ComplexVec of rcomplex array
  | StrVec of rstring array
  | BoolVec of rbool array

type value =
  | Vec of rvector
  | RefArray of memref list
  | FuncVal of param list * expr * memref
  | EnvVal of env
  | ListVal of (ident option * memref) list

type attributes =
  { rstr_map : (rstring, memref) Hashtbl.t }

(* Stack *)
type slot =
    ReturnSlot of memref
  | UpdateSlot of memref
  | EvalSlot of expr
  | SeqSlot of expr list
  | ArgsSlot of arg list
  | AttrSlot of memref option * expr option
  | LoopSlot of expr * expr * memref option (* body's return value *)
  | BranchSlot of expr * expr

type frame =
  { env_mem : memref;
    slot : slot }

type stack =
  { frame_list : frame list }


(* Heap *)
type heapobj =
    PromiseObj of expr * memref
  | DataObj of value * attributes

type heap =
  { mem_map : heapobj MemRefMap.t;
    next_mem : memref }

(* Execution state *)
type state =
  { stack : stack;
    heap : heap;
    global_env_mem : memref;
    fresh_count : int }


(* Utility functions *)

(* Memory references *)
let mem_of_int : int -> memref =
  fun addr -> { R.addr = addr }

let mem_incr : memref -> memref =
  fun mem -> { mem with R.addr = mem.R.addr + 1 }

let mem_null : memref = mem_of_int 0

let is_mem_null : memref -> bool =
  fun mem -> mem = mem_null


(* R type utility *)
let rint_of_int : int -> rint =
  fun i -> Some i

let na_rint : rint = None

let rfloat_of_float : float -> rfloat =
  fun f -> Some f

let na_rfloat : rfloat = None

let rcomplex_of_complex : Complex.t -> rcomplex =
  fun c -> Some c

let na_rcomplex : rcomplex = None

let rbool_of_bool : int -> rbool =
  fun b -> Some b

let na_rbool : rbool = None

let rstring_of_string : string -> rstring =
  fun s -> Some s

let na_rstring : rstring = None

(* Fresh identifier *)
let id_default : ident =
  { R.pkg = None;
    R.name = na_rstring;
    R.tag = None }

let id_of_rstring : rstring -> ident =
  fun name -> { id_default with R.name = name }

let id_fresh : state -> ident * state =
  fun state ->
    let count2 = state.fresh_count + 1 in
    let name = rstring_of_string ("fs$" ^ string_of_int count2) in
      (id_of_rstring name, { state with fresh_count = count2 })

let rec id_fresh_list : int -> state -> (ident list) * state =
  fun n state ->
    if n < 1 then
      ([], state)
    else
      let (id, state2) = id_fresh state in
      let (ids_tl, state3) = id_fresh_list (n - 1) state2 in
        (id :: ids_tl, state3)


(* Attributes *)
let attrs_empty : attributes =
  { rstr_map = Hashtbl.create 20 } (* TODO: what is the expected size? *)

let attrs_find : rstring -> attributes -> memref option =
  fun rstr attrs ->
    try
      Some (Hashtbl.find attrs.rstr_map rstr)
    with
      Not_found -> None

let attrs_add : rstring -> memref -> attributes -> unit =
  fun rstr mem attrs ->
    Hashtbl.add attrs.rstr_map rstr mem

let rec attrs_add_list : (rstring * memref) list -> attributes -> unit =
  fun binds attrs ->
    match binds with
    | [] -> ()
    | ((rstr, mem) :: binds_tl) ->
        attrs_add rstr mem attrs;
        attrs_add_list binds_tl attrs;;

(* Frame operations *)
let frame_default : frame =
  { env_mem = mem_null;
    slot = ReturnSlot mem_null }


(* Stack operations *)
let stack_empty : stack =
  { frame_list = [] }

let stack_pop : stack -> (frame * stack) option =
  fun stack ->
    match stack.frame_list with
    | [] -> None
    | (frame :: frames_tl) ->
        Some (frame, { stack with frame_list = frames_tl })

let stack_pop_v : stack -> (slot * memref * stack) option =
  fun stack ->
    match stack_pop stack with
    | None -> None
    | Some (frame, stack2) ->
        Some (frame.slot, frame.env_mem, stack2)

let stack_pop_v2 : stack -> (slot * memref * slot * memref * stack) option =
  fun stack ->
    match stack_pop_v stack with
    | None -> None
    | Some (slot1, env_mem1, stack2) ->
      match stack_pop_v stack2 with
      | None -> None
      | Some (slot2, env_mem2, stack3) ->
          Some (slot1, env_mem1, slot2, env_mem2, stack3)

let stack_push : frame -> stack -> stack =
  fun frame stack ->
    { stack with frame_list = frame :: stack.frame_list }

let rec stack_push_list : frame list -> stack -> stack =
  fun frames stack ->
    match frames with
    | [] -> stack
    | (frame :: frames_tl) ->
        stack_push frame (stack_push_list frames_tl stack)


(* Heap operations *)
let heap_empty : heap =
  { mem_map = MemRefMap.empty;
    next_mem = mem_incr mem_null }

let heap_find : memref -> heap -> heapobj option =
  fun mem heap ->
    try
      Some (MemRefMap.find mem heap.mem_map)
    with
      Not_found -> None

let rec heap_find_deep : memref -> heap -> (memref * heapobj) option =
  fun mem heap ->
    match heap_find mem heap with
    | None -> None
    | Some (PromiseObj (R.MemRef mem2, _)) -> heap_find_deep mem2 heap
    | Some hobj -> Some (mem, hobj)

let heap_add : memref -> heapobj -> heap -> heap =
  fun mem hobj heap ->
    { heap with mem_map = MemRefMap.add mem hobj heap.mem_map }

let rec heap_add_list : (memref * heapobj) list -> heap -> heap =
  fun binds heap ->
    match binds with
    | [] -> heap
    | ((mem, hobj) :: binds_tl) ->
        heap_add_list binds (heap_add mem hobj heap)

let heap_alloc : heapobj -> heap -> memref * heap =
  fun hobj heap ->
    let used_mem = heap.next_mem in
      (used_mem, { (heap_add used_mem hobj heap) with
                     next_mem = mem_incr used_mem })

let rec heap_alloc_list : heapobj list -> heap -> memref list * heap =
  fun hobjs heap ->
    match hobjs with
    | [] -> ([], heap)
    | (hobj :: hobjs_tl) ->
        let (mem, heap2) = heap_alloc hobj heap in
        let (mems_tl, heap3) = heap_alloc_list hobjs_tl heap2 in
          (mem :: mems_tl, heap3)

let heap_alloc_const : R.const -> heap -> (memref * heap) =
  fun const heap ->
    heap_alloc
      (DataObj ((match const with
          R.Str s -> Vec (StrVec (Array.of_list [s]))
        | R.Num (R.Int i) -> Vec (IntVec (Array.of_list [i]))
        | R.Num (R.Float f) -> Vec (FloatVec (Array.of_list [f]))
        | R.Num (R.Complex c) -> Vec (ComplexVec (Array.of_list [c]))
        | R.Bool b -> Vec (BoolVec (Array.of_list [b]))
        | R.Nil -> Vec (BoolVec (Array.of_list []))
        ), attrs_empty)) heap

let heap_remove : memref -> heap -> heap =
  fun mem heap ->
    { heap with mem_map = MemRefMap.remove mem heap.mem_map }

let rec heap_remove_list : memref list -> heap -> heap =
  fun mems heap ->
    match mems with
    | [] -> heap
    | (mem :: mems_tl) -> heap_remove_list mems_tl (heap_remove mem heap)


(* Environment functions *)

let env_empty : env =
  { id_map = IdentMap.empty;
    pred_mem = mem_null }

(* Flattening *)
let list_of_mem : env -> (ident * memref) list =
  fun env ->
    IdentMap.bindings env.id_map

(* First occurrence within the environment *)
let rec env_find : ident -> env -> heap -> memref option =
  fun id env heap ->
    try
      Some (IdentMap.find id env.id_map)
    with
      Not_found ->
        match heap_find env.pred_mem heap with
        | Some (DataObj (EnvVal env2, _)) -> env_find id env2 heap
        | _ -> None

let env_mem_find : ident -> memref -> heap -> memref option =
  fun id env_mem heap ->
    match heap_find env_mem heap with
    | Some (DataObj (EnvVal env, _)) -> env_find id env heap
    | _ -> None

(* Find first occurrence whose package matches *)

(* Add to outrmost level of environment *)
let env_add : ident -> memref -> env -> env =
  fun id mem env ->
    { env with id_map = IdentMap.add id mem env.id_map }

let rec env_add_list : (ident * memref) list -> env -> env =
  fun binds env ->
    match binds with
    | [] -> env
    | ((id, mem) :: binds_tl) ->
        env_add_list binds_tl (env_add id mem env)

let env_mem_add : ident -> memref -> memref -> heap -> heap option =
  fun id mem env_mem heap ->
    match heap_find env_mem heap with
    | Some (DataObj (EnvVal env, attrs)) ->
        let env2 = env_add id mem env in
          Some (heap_add env_mem (DataObj (EnvVal env2, attrs)) heap)
    | _ -> None

let env_mem_add_list :
  (ident * memref) list -> memref -> heap -> heap option =
  fun binds env_mem heap ->
    match heap_find env_mem heap with
    | Some (DataObj (EnvVal env, attrs)) ->
        let env2 = env_add_list binds env in
          Some (heap_add env_mem (DataObj (EnvVal env2, attrs)) heap)
    | _ -> None

let env_remove : ident -> env -> env =
  fun id env ->
    { env with id_map = IdentMap.remove id env.id_map }

let rec env_remove_list : ident list -> env -> env =
  fun ids env ->
    match ids with
    | [] -> env
    | (id :: ids_tl) -> env_remove_list ids_tl (env_remove id env)

let rec env_mem_remove_all : ident -> memref -> heap -> heap option =
  fun id env_mem heap ->
    match heap_find env_mem heap with
    | Some (DataObj (EnvVal env, attrs)) ->
        let env2 = env_remove id env in
        let heap2 = heap_add env_mem (DataObj (EnvVal env2, attrs)) heap in
          if is_mem_null env.pred_mem || env_mem = env.pred_mem then
            Some heap2
          else
            env_mem_remove_all id env.pred_mem heap2
    | _ -> None

let rec env_mem_remove_all_list : ident list -> memref -> heap -> heap option =
  fun ids env_mem heap ->
    match ids with
    | [] -> Some heap
    | (id :: ids_tl) ->
      match env_mem_remove_all id env_mem heap with
      | None -> None
      | Some heap2 -> env_mem_remove_all_list ids_tl env_mem heap2

let env_nest : memref -> env =
  fun env_mem ->
    { env_empty with pred_mem = env_mem }


