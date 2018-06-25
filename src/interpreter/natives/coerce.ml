module S = Support

let resolve_vec: 'a option array -> 'a array =
    fun v ->
    Array.map (fun x -> match x with
        | Some x' -> x'
        | None    -> failwith "NA when resolving vector") v

let unresolve_vec: 'a array -> 'a option array =
    fun v ->
    Array.map (fun x -> Some x) v

let rvector_to_int_array: S.rvector -> S.rint array =
    fun vec -> match vec with
    | S.IntVec i  -> i
    | _         -> failwith "can't cast vector to int array!" (* TODO other types can be coerced *)

let rvector_to_str_array: S.rvector -> S.rstring array =
    fun vec -> match vec with
    | S.StrVec s -> s
    | _         -> failwith "can't cast vector to string array!"

let value_to_rvector: S.value -> S.rvector =
    fun value -> match value with
    | S.Vec vec   -> vec
    | _         -> failwith "can't cast! to rvector!" (* TODO: lists can be coerced *)

let value_to_int_array: S.value -> S.rint array =
    fun value -> let vec = value_to_rvector value in
    rvector_to_int_array vec

let dereference_rvector: S.memref -> S.heap -> S.rvector =
    fun mem heap ->
    match S.heap_find mem heap with
    | Some (S.DataObj (S.Vec v, _)) -> v
    | _ -> failwith "Vec expected in dereference"

(* TODO: catch a dereference error somehow? *)
let dereference: S.memref list -> S.heap -> S.heapobj list =
    fun mems heap ->
    List.map (fun mem -> S.MemRefMap.find mem heap.S.mem_map) mems

