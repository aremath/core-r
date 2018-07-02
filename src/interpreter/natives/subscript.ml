module S = Support
module C = Coerce
module V = Vector

(* The offset array tells the subscripter how much variation in a single dimension
 affects the linear index. For example, if x is a 5x2 vector it is stored in memory
 as a length-10 vector. The value x[[3,0]] is physically directly before the value
 x[[4,0]], but the value x[[0,0]] is stored 5 places before x[[0,1]] *)
let make_offset : int array -> int array =
  fun dims -> 
    let n = Array.length dims in
    let out = Array.make n 1 in
    let _ = for i = 1 to n-1 do
        out.(i) <- out.(i-1) * dims.(i-1)
    done in
    out

(* Finds a list of indices given a list of bounds and the number of iteration we are on.
 Each index is on a loop number equal to the number of total loops that come below it,
 calculated as n/div, modulo the iterator for that loop. *)
let find_indices : int -> int array -> int array =
  fun n bounds ->
    Array.mapi (fun i v -> 
        let bounds_before = Array.sub bounds 0 i in
        let div = Array.fold_left (fun x y -> x * y) 1 bounds_before in
        (n / div) mod v
    ) bounds

let index_sub : int array -> int -> int =
  fun sub index -> 
    sub.(index mod (Array.length sub))

(* calculate the actual linear index in the array, based on indices into
 the list of subs *)
let index_subs : int array -> (int array) list -> int array -> int -> int =
  fun indices subs offset n_dims ->
    (* get an array from 0 to n_dims *)
    let dim_array = Array.init n_dims (fun x -> x) in
    let iis = Array.map (fun n -> 
        let sub_n = List.nth subs n in
        let result = index_sub sub_n (Array.get indices n) in
        (result - 1) * (Array.get offset n)) dim_array in
    Array.fold_left (+) 0 iis

(* Produce a vector which is the right subset of the original,
 given the dimensions of the original vector, and which indices to
 slice. *)
let do_subset: ('a array * int array) -> int array list -> ('a array * int array) =
    fun (in_array, in_dims) subs ->
    let n_dims = Array.length in_dims in
    (* bounds is the dimension of out_array *)
    let bounds = Array.of_list (List.map (fun x -> Array.length x) subs) in
    let offset = make_offset in_dims in
    let n_elements = Array.fold_left (fun x y -> x*y) 1 bounds in
    (* TODO: need a way to get a "null 'a" to fill out_array with *)
    let out_array = Array.make n_elements in_array.(0) in
    (* holds the current index in each dimension of in_array *)
    let _ = for i = 0 to n_elements - 1 do
       let indices = find_indices i bounds in 
       let ii = index_subs indices subs offset n_dims in
       out_array.(i) <- in_array.(ii)
    done in
    (out_array, bounds)

(* thanks ocaml types *)
let do_subset_int: (int option array * int array) -> int array list -> (int array * int array) =
    fun (i,idims) subs ->
        do_subset ((C.resolve_vec i), idims) subs

let do_subset_float: (float option array * int array) -> int array list -> (float array * int array) =
    fun (i, idims) subs ->
        do_subset ((C.resolve_vec i), idims) subs

let do_subset_complex: (Complex.t option array * int array) -> int array list -> (Complex.t array * int array) =
    fun (i, idims) subs ->
        do_subset ((C.resolve_vec i), idims) subs

let do_subset_string: (string option array * int array) -> int array list -> (string array * int array) =
    fun (i, idims) subs ->
        do_subset ((C.resolve_vec i), idims) subs

let do_subset_bool: (int option array * int array) -> int array list -> (int array * int array) =
    fun (i, idims) subs ->
        do_subset ((C.resolve_vec i), idims) subs

let subset_mems: S.memref -> S.memref list -> S.heap -> (S.memref * S.heap) =
    fun data_ref sub_refs heap ->
    (* args is a list of memrefs to the constants we're using for the subset 
    we want to convert it to an rvector list for ease of use. *)
    (* TODO: implicit defaults and negative indices *)
    let subs = List.map (fun m ->
        let rvec = C.dereference_rvector m heap in
        C.resolve_vec (C.rvector_to_int_array rvec)) tl in
    match S.heap_find data_ref heap with
    | Some (S.DataObj (data_val, data_attributes)) ->
        (* find the dims as a reference *)
        let data_dims_ref = begin match S.attrs_find (Some "dim") data_attributes with
            | Some (v)  -> v
            | None      -> failwith "data has no dim attribute" (* TODO: this can be valid, i.e. when the array is one-dimensional *)
        end in
        let data_dims = C.dereference_rvector data_dims_ref heap in
        (* coerce it to an int array *)
        let data_dims_val = C.resolve_vec (C.rvector_to_int_array data_dims) in
        (* get data as an rvector *)
        let data_rvector = C.value_to_rvector data_val in
        let slice_rvec, slice_dims = begin match data_rvector with
        | S.IntVec i      -> let (iv, id) = do_subset_int (i, data_dims_val) subs in
            S.IntVec (C.unresolve_vec iv), S.IntVec (C.unresolve_vec id)
        | S.FloatVec f    -> let (fv, fd) = do_subset_float (f, data_dims_val) subs in
            S.FloatVec (C.unresolve_vec fv), S.IntVec (C.unresolve_vec fd)
        | S.ComplexVec c  -> let (cv, cd) = do_subset_complex (c, data_dims_val) subs in
            S.ComplexVec (C.unresolve_vec cv), S.IntVec (C.unresolve_vec cd)
        | S.StrVec s      -> let (sv, sd) = do_subset_string (s, data_dims_val) subs in
            S.StrVec (C.unresolve_vec sv), S.IntVec (C.unresolve_vec sd)
        | S.BoolVec b     -> let (bv, bd) = do_subset_bool (b, data_dims_val) subs in
            S.BoolVec (C.unresolve_vec bv), S.IntVec (C.unresolve_vec bd)
        end in
        (* allocate dims on the heap, give data it as dim *)
        let slice_dims_mem, heap' = S.heap_alloc (S.DataObj (S.Vec (slice_dims), S.attrs_empty)) heap in
        let slice_attrs = S.attrs_empty in
        let _ = S.attrs_add (Some "dim") slice_dims_mem in
        (* allocate data on the heap *)
        S.heap_alloc (S.DataObj (S.Vec (slice_rvec), slice_attrs)) heap'
    | Some _ -> failwith "Data is a promise"
    | None   -> failwith "Data does not exist" 

(* find the index of x in a - used to index a vector by its names attribute *)
let rec find : 'a array -> 'a -> int -> int =
  fun a x n -> 
    if a.(n) = x then n else
    find a x (n+1)

let subscript_str: S.rvector -> S.rstring array -> S.rstring array -> S.heap -> (S.memref * S.heap) = 
    fun data_rvec names subscript_vec heap ->
    let _ = if Array.length subscript_vec = 1 then () else failwith "Subscript of length not 1" in
    let sub = subscript_vec.(0) in
    let idx = find names sub 0 in
    let out_rvec = match data_rvec with
    | S.IntVec i -> S.IntVec (Array.make 1 i.(idx))
    | S.FloatVec f -> S.FloatVec (Array.make 1 f.(idx))
    | S.ComplexVec c -> S.ComplexVec (Array.make 1 c.(idx))
    | S.StrVec s -> S.StrVec (Array.make 1 s.(idx))
    | S.BoolVec b -> S.BoolVec (Array.make 1 b.(idx)) in
    S.heap_alloc (S.DataObj ((S.Vec out_rvec), S.attrs_empty)) heap

let subscript_int: S.rvector -> int array -> S.heap -> (S.memref * S.heap) =
    fun data_rvec subscript_vec heap ->
        let _ = if Array.length subscript_vec = 1 then () else failwith "Subscript of length not 1" in
        (* the index to get *)
        let n = subscript_vec.(0) in
        let _ = if n = 0 then failwith "0 subscript" else () in
        let true_n = if n < 0 then (V.rvec_length data_rvec) + (n - 1) else n - 1 in
        let sub_rvec = begin match data_rvec with
        | S.IntVec i -> let v = i.(true_n) in
            S.IntVec (Array.make 1 v)
        | S.FloatVec f -> let v = f.(true_n) in
            S.FloatVec (Array.make 1 v)
        | S.ComplexVec c -> let v = c.(true_n) in
            S.ComplexVec (Array.make 1 v)
        | S.StrVec s -> let v = s.(true_n) in
            S.StrVec (Array.make 1 v)
        | S.BoolVec b -> let v = b.(true_n) in
            S.BoolVec (Array.make 1 v)
        end in
        (* allocate it as a data object on the heap *)
        S.heap_alloc (S.DataObj ((S.Vec sub_rvec), S.attrs_empty)) heap

let subscript_mems: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref subscript_ref heap ->
    match S.heap_find data_ref heap with
    | Some (S.DataObj (S.Vec data_rvec, data_attrs)) ->
        begin match C.dereference_rvector subscript_ref heap with
        | S.StrVec subscript_vec -> let names_ref = begin
                match S.attrs_find (Some "names") data_attrs with
                | Some r -> r
                | None -> failwith "Cannot string subscript a vector with no names attribute"
                end in
            (* get the names attribute *)
            let names = C.rvector_to_str_array (C.dereference_rvector names_ref heap) in
            subscript_str data_rvec names subscript_vec heap
        | rvec -> let subscript_vec = C.rvector_to_int_array rvec in
            subscript_int data_rvec (C.resolve_vec subscript_vec) heap
        end
    | _ -> failwith "Vector expected"

