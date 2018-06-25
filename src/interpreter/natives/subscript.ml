module S = Support
module C = Coerce
module V = Vector

let resolve_vec: 'a option array -> 'a array =
    fun v ->
    Array.map (fun x -> match x with
        | Some x' -> x'
        | None    -> failwith "NA when resolving vector") v

let unresolve_vec: 'a array -> 'a option array =
    fun v ->
    Array.map (fun x -> Some x) v

(* The offset array tells the subscripter how much variation in a single dimension
 affects the linear index. For example, if x is a 5x2 vector it is stored in memory
 as a length-10 vector. The value x[[3,0]] is physically directly before the value
 x[[4,0]], but the value x[[0,0]] is stored 5 places before x[[0,1]] *)
let make_offset dims =
    let n = Array.length dims in
    let out = Array.make n 1 in
    let _ = for i = 1 to n-1 do
        out.(i) <- out.(i-1) * dims.(i-1)
    done in
    out

(* Finds a list of indices given a list of bounds and the number of iteration we are on.
 Each index is on a loop number equal to the number of total loops that come below it,
 calculated as n/div, modulo the iterator for that loop. *)
let find_indices n bounds =
    Array.mapi (fun i v -> 
        let bounds_before = Array.sub bounds 0 i in
        let div = Array.fold_left (fun x y -> x * y) 1 bounds_before in
        (n / div) mod v
    ) bounds

let index_sub sub index =
    sub.(index mod (Array.length sub))

(* calculate the actual linear index in the array, based on indices into
 the list of subs *)
let index_subs indices subs offset n_dims =
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
        do_subset ((resolve_vec i), idims) subs

let do_subset_float: (float option array * int array) -> int array list -> (float array * int array) =
    fun (i, idims) subs ->
        do_subset ((resolve_vec i), idims) subs

let do_subset_complex: (Complex.t option array * int array) -> int array list -> (Complex.t array * int array) =
    fun (i, idims) subs ->
        do_subset ((resolve_vec i), idims) subs

let do_subset_string: (string option array * int array) -> int array list -> (string array * int array) =
    fun (i, idims) subs ->
        do_subset ((resolve_vec i), idims) subs

let do_subset_bool: (int option array * int array) -> int array list -> (int array * int array) =
    fun (i, idims) subs ->
        do_subset ((resolve_vec i), idims) subs

let subset_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun args heap ->
    (* args is a list of memrefs to the constants we're using for the subset 
    we want to convert it to an rvector list for ease of use. *)
    (* TODO: implicit defaults and negative indices *)
    match args with
    | data_ref::tl -> let subs = List.map (fun m ->
            let rvec = C.dereference_rvector m heap in
            resolve_vec (C.rvector_to_int_array rvec)) tl in
        begin match S.heap_find data_ref heap with
        | Some (S.DataObj (data_val, data_attributes)) ->
            (* find the dims as a reference *)
            let data_dims_ref = begin match S.attrs_find (Some "dim") data_attributes with
                | Some (v)  -> v
                | None      -> failwith "data has no dim attribute" (* TODO: this can be valid, i.e. when the array is one-dimensional *)
            end in
            let data_dims = C.dereference_rvector data_dims_ref heap in
            (* coerce it to an int array *)
            let data_dims_val = resolve_vec (C.rvector_to_int_array data_dims) in
            (* get data as an rvector *)
            let data_rvector = C.value_to_rvector data_val in
            let slice_rvec, slice_dims = begin match data_rvector with
            | S.IntVec i      -> let (iv, id) = do_subset_int (i, data_dims_val) subs in
                S.IntVec (unresolve_vec iv), S.IntVec (unresolve_vec id)
            | S.FloatVec f    -> let (fv, fd) = do_subset_float (f, data_dims_val) subs in
                S.FloatVec (unresolve_vec fv), S.IntVec (unresolve_vec fd)
            | S.ComplexVec c  -> let (cv, cd) = do_subset_complex (c, data_dims_val) subs in
                S.ComplexVec (unresolve_vec cv), S.IntVec (unresolve_vec cd)
            | S.StrVec s      -> let (sv, sd) = do_subset_string (s, data_dims_val) subs in
                S.StrVec (unresolve_vec sv), S.IntVec (unresolve_vec sd)
            | S.BoolVec b     -> let (bv, bd) = do_subset_bool (b, data_dims_val) subs in
                S.BoolVec (unresolve_vec bv), S.IntVec (unresolve_vec bd)
            end in
            (* allocate dims on the heap, give data it as dim *)
            let slice_dims_mem, heap' = S.heap_alloc (S.DataObj (S.Vec (slice_dims), S.attrs_empty)) heap in
            let slice_attrs = S.attrs_empty in
            let _ = S.attrs_add (Some "dim") slice_dims_mem in
            (* allocate data on the heap *)
            S.heap_alloc (S.DataObj (S.Vec (slice_rvec), slice_attrs)) heap'
        | _ -> failwith "data is a promise" end
    | _ -> failwith "Bad call to subset"

let subscript_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun args heap ->
    match args with
    | [data_mem;subscript_mem] -> let subscript_vec = 
            resolve_vec (C.rvector_to_int_array 
            (C.dereference_rvector subscript_mem heap)) in
        let data_rvec = C.dereference_rvector data_mem heap in
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
    | _ -> failwith "Bad call to subscript"

