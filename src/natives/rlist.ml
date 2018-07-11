module S = Support
module C = Native_support
module Copy = Copy

(* Top level length of a list *)
let list_length_mems: S.memref -> S.heap -> (S.memref * S.heap) =
    fun list_ref heap ->
    let lst = C.dereference_rlist list_ref heap in
    List.length lst

(* It might seem silly, but make_list expects its arguments as a ListVal. This is
 because it takes variadic arguments, and variadic arguments are passed as ListVal to
 allow for things like ex.
    list(ayy=c(1), lmao=c(2))
 which is passed as
    ListVal [(Some "ayy", ref to c(1))::(Some "lmao", ref to c(2))]
 The resulting list should actually be the same as the arguments passed, but copied
 since the arguments are captured.
 TODO: should have a names attribute
 *)
let make_list_mems: S.memref -> S.heap -> (S.memref * S.heap) =
    fun list_ref heap ->
    Copy.deep_copy list_ref heap

let rec split_rarray: ('a -> S.heapobj) -> 'a array -> heap -> int -> (S.memref list * heap) =
    fun f a heap n ->
    if n = Array.length a then
        ([], heap)
    else
    (* Create a single heap object from the nth element of a *)
    let obj = f a.(n) in
    let mem, heap' = S.heap_alloc obj heap in
    let (mems, heap'') = split_rints a heap' (n+1) in
    mem::mems, heap''

let mk_intvec: S.rint -> S.heapobj =
    fun i -> S.DataObj(S.Vec (S.IntVec [|i|]), S.attrs_empty)
let mk_floatvec: S.rfloat -> S.heapobj =
    fun f -> S.DataObj(S.Vec (S.FloatVec [|f|]), S.attrs_empty)
let mk_complexvec: S.rcomplex -> S.heapobj =
    fun c -> S.DataObj(S.Vec (S.ComplexVec [|c|]), S.attrs_empty)
let mk_strvec: S.rstring -> S.heapobj =
    fun s -> S.DataObj(S.Vec (S.StrVec [|s|]), S.attrs_empty)
let mk_boolvec: S.rbool -> S.heapobj =
    fun b -> S.DataObj(S.Vec (S.BoolVec [|b|]), S.attrs_empty)

(* TODO: should this be in vector.ml? *)
(* Make n individual rvectors from a vector of length n *)
let split_rvector: S.rvector -> heap -> (S.memref list * heap) =
    fun vec heap ->
       match vec with
       | S.IntVec i -> split_rarray mk_intvec i heap 0
       | S.FloatVec f -> split_rarray mk_floatvec f heap 0
       | S.ComplexVec c -> split_rarray mk_complexvec c heap 0
       | S.StrVec s -> split_rarray mk_strvec s heap 0
       | S.BoolVec b -> split_rarray mk_boolvec b heap 0

(* Conversion *)
(* TODO: this does the conversion without reference to the 'names' attribute.
 What should happen is that the vector's names are transferred to the new list.
 This requires converting the vector's names into a list as well. *)
(* TODO: bad if we allocate the attrs only to have a problem somewhere else? *)
let list_of_vector_mems: S.memref -> S.heap -> (S.memref * S.heap) =
    fun vec_ref heap ->
    let vec, vec_attrs = match S.heap_find vec_ref heap with
    | Some (S.DataObj (S.Vec v, vattrs)) -> v, vattrs
    | _ -> failwith "Invalid vector argument in list_of_vector"
    in
    (* TODO: use the attrs to get a [rstring] which can populate the first half
    of each tuple in the list *)
    (* Change the vector into a list of length-1 vectors allocated separately *)
    let vec_refs, heap'' = split_rvector vec heap' in
    (* Make a ListVal from the references list, then allocate it *)
    let new_list = S.ListVal (List.map (fun ref -> (None, ref)) vec_refs) in
    S.heap_alloc S.DataObj(new_list, S.attrs_empty) heap''

