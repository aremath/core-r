module S = Support
module C = Native_support
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

(* Creates an array which is every index of the large array used in the slice.
  At the end of do_subset, out.(i) = in.(mk_indices.(i)).
  Used in [<- for determining which indices the user is trying to set. *)
let out_indices: int -> int array -> int array list -> int array -> int -> int array =
    fun n_elements bounds subs offset n_dims ->
    let index_array = Array.make n_elements 0 in
    let _ = for i = 0 to n_elements - 1 do
        (* holds the current index in each dimension of in_array *)
       let indices = find_indices i bounds in 
       let ii = index_subs indices subs offset n_dims in
       index_array.(i) <- ii
    done in
    index_array

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
    let out_array = Array.make n_elements in_array.(0) in
    (* Find which indices of in_array the out_array contains *)
    let final_indices = out_indices n_elements bounds subs offset n_dims in
    (* Do the assignments *)
    let _ = Array.iteri (fun i v -> out_array.(i) <- in_array.(v)) final_indices in
    (out_array, bounds)

(* thanks ocaml types :( *)
let do_subset_int: (S.rint array * int array) -> int array list -> (S.rvector * S.rvector) =
    fun (i,idims) subs ->
        let iv, id = do_subset (i, idims) subs in
        S.IntVec iv, S.IntVec (C.unresolve_vec id)

let do_subset_float: (S.rfloat array * int array) -> int array list -> (S.rvector * S.rvector) =
    fun (i, idims) subs ->
        let fv, fd = do_subset (i, idims) subs in
        S.FloatVec fv, S.IntVec (C.unresolve_vec fd)

let do_subset_complex: (S.rcomplex array * int array) -> int array list -> (S.rvector * S.rvector) =
    fun (i, idims) subs ->
        let cv, cd = do_subset (i, idims) subs in
        S.ComplexVec cv, S.IntVec (C.unresolve_vec cd)

let do_subset_string: (S.rstring array * int array) -> int array list -> (S.rvector * S.rvector) =
    fun (i, idims) subs ->
        let sv, sd = do_subset (i, idims) subs in
        S.StrVec sv, S.IntVec (C.unresolve_vec sd)

let do_subset_bool: (S.rint array * int array) -> int array list -> (S.rvector * S.rvector) =
    fun (b, bdims) subs ->
        let bv, bd = do_subset (b, bdims) subs in
        S.BoolVec bv, S.IntVec (C.unresolve_vec bd)

(* Assign assign_array to the correct slice of in_array. Checks that the assign_array is
 a multiple of the slice size *)
let do_subset_assign: ('a array * int array) -> int array list -> 'a array -> unit =
    fun (in_array, in_dims) subs assign_array ->
    let n_dims = Array.length in_dims in
    (* bounds is the dimension of out_array *)
    let bounds = Array.of_list (List.map (fun x -> Array.length x) subs) in
    let offset = make_offset in_dims in
    let n_elements = Array.fold_left (fun x y -> x*y) 1 bounds in
    (* Make sure the assign_array is a multiple of the slice size *)
    let n_assigns = Array.length assign_array in
    let _ = if n_elements mod n_assigns <> 0 then
        failwith "Number of items to replace is not a multiple of replacement length"
        else () in
    let out_array = Array.make n_elements (0, in_array.(0)) in
    (* Find which indices of in_array will be assigned to *)
    let final_indices = out_indices n_elements bounds subs offset n_dims in
    (* Do the assignments - wrap assigns using mod *)
    Array.iteri (fun i v -> in_array.(v) <- assign_array.(i mod n_assigns)) final_indices

let do_subset_assign_int: (S.rint array * int array) -> int array list -> S.rint array -> unit =
    fun (i, idims) subs iassign ->
        do_subset_assign (i, idims) subs iassign;;

let do_subset_assign_float: (S.rfloat array * int array) -> int array list -> S.rfloat array -> unit =
    fun (f, fdims) subs fassign ->
        do_subset_assign (f, fdims) subs fassign;;

let do_subset_assign_complex: (S.rcomplex array * int array) -> int array list -> S.rcomplex array -> unit =
    fun (c, cdims) subs cassign ->
        do_subset_assign (c, cdims) subs cassign;;

let do_subset_assign_string: (S.rstring array * int array) -> int array list -> S.rstring array -> unit =
    fun (s, sdims) subs sassign ->
        do_subset_assign (s, sdims) subs sassign;;

let do_subset_assign_bool: (S.rbool array * int array) -> int array list -> S.rbool array -> unit =
    fun (b, bdims) subs bassign ->
        do_subset_assign (b, bdims) subs bassign;;

(* TODO: implicit defaults and negative indices *)
(* convert the list of subset references to the actual list of integer arrays that will
 be used for the subset *)
let sub_refs_to_subs: S.memref list -> S.heap -> int array list =
    fun sub_refs heap ->
    List.map (fun m ->
        let rvec = C.dereference_rvector m heap in
        C.resolve_vec (C.rvector_to_int_array rvec)) sub_refs

let get_dims: S.attributes -> S.heap -> int array =
    fun attrs heap ->
    let data_dims_ref = begin match S.attrs_find (Some "dim") attrs with
        | Some (v)  -> v
        (* TODO: this can be valid, i.e. when the array is one-dimensional *)
        | None      -> failwith "data has no dim attribute" 
    end in
    let data_dims = C.dereference_rvector data_dims_ref heap in
    (* coerce it to an int array *)
    C.resolve_vec (C.rvector_to_int_array data_dims)

(* Produces a slice from data *)
let rvector_slice: S.rvector -> int array -> int array list -> (S.rvector * S.rvector) =
    fun data data_dims subs ->
    match data with
    | S.IntVec i -> do_subset_int (i, data_dims) subs 
    | S.FloatVec f -> do_subset_float (f, data_dims) subs
    | S.ComplexVec c -> do_subset_complex (c, data_dims) subs
    | S.StrVec s -> do_subset_string (s, data_dims) subs
    | S.BoolVec b -> do_subset_bool (b, data_dims) subs

(* TODO: For a vector with dimnames, can also do 
 ex. v["a", "b",], which slices by the dimension name *)
(* TODO: For a vector with names, ex. v=c(a=1,b=2), we know that
 v[1] retains a copy of v's names attribute, but reduced to
 cover the vector. In this case:
    names(v) = c("a", "b") and
    names(v[1]) = c("a")
 The same thing happens when slicing a vector by its dimnames -
 The sliced vector should retain a (possibly smaller) version of the dimnames
 which corresponds to the dimensions it still has. This works pretty weird if
 v has both a "dimnames" and a "names" attribute - it seems like single-element
 subsetting and subscripting use "names" while multi-element subsetting and
 subscripting use "dimnames".
*)
(* v[x] *)
let subset_mems: S.memref -> S.memref list -> S.heap -> (S.memref * S.heap) =
    fun data_ref sub_refs heap ->
    (* args is a list of memrefs to the constants we're using for the subset 
    we want to convert it to an rvector list for ease of use. *)
    let subs = sub_refs_to_subs sub_refs heap in
    match S.heap_find data_ref heap with
    | Some (S.DataObj (S.Vec data_rvector, data_attributes)) ->
        let data_dims = get_dims data_attributes heap in
        (* get data as an rvector *)
        let slice_rvec, slice_dims = rvector_slice data_rvector data_dims subs in
        (* allocate dims on the heap, give it to data as dim *)
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
    find a x (n+1) (* Will error out if it reaches the end without finding *)

(* TODO: names might be dimnames! *)
(* Find the index of subscript_vec in names *)
let find_names_index: S.rstring array -> S.rstring array -> int =
    fun names subscript_vec ->
    let _ = if Array.length subscript_vec = 1 then () else failwith "Subscript of length not 1" in
    let sub = subscript_vec.(0) in
    find names sub 0

let subscript_str: S.rvector -> S.rstring array -> S.rstring array -> S.heap -> (S.memref * S.heap) = 
    fun data_rvec names subscript_vec heap ->
    let idx = find_names_index names subscript_vec in
    let out_rvec = match data_rvec with
    | S.IntVec i -> S.IntVec (Array.make 1 i.(idx))
    | S.FloatVec f -> S.FloatVec (Array.make 1 f.(idx))
    | S.ComplexVec c -> S.ComplexVec (Array.make 1 c.(idx))
    | S.StrVec s -> S.StrVec (Array.make 1 s.(idx))
    | S.BoolVec b -> S.BoolVec (Array.make 1 b.(idx)) in
    S.heap_alloc (S.DataObj ((S.Vec out_rvec), S.attrs_empty)) heap

(* Find the true index into the vector given an integer *)
let find_int_index: int -> int array -> int =
    fun data_length subscript_vec ->
    let _ = if Array.length subscript_vec = 1 then () else failwith "Subscript of length not 1" in
    (* the index to get *)
    let n = subscript_vec.(0) in
    let _ = if n = 0 then failwith "0 subscript" else () in
    if n < 0 then (data_length) + (n - 1) else n - 1

let subscript_int: S.rvector -> int array -> S.heap -> (S.memref * S.heap) =
    fun data_rvec subscript_vec heap ->
    let true_n = find_int_index (V.rvec_length data_rvec) subscript_vec in
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

(* v[[x]] *)
let subscript_mems: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref subscript_ref heap ->
    match S.heap_find data_ref heap with
    | Some (S.DataObj (S.Vec data_rvec, data_attrs)) ->
        (* If it's a string, we're supposed to lookup in the names attribute *)
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

(* Puts the first element of vec into data_vec at index
 DOES NOT COPY - intended for use with a pre-copied vector *)
let do_replace: S.rvector -> (int * S.rvector) -> unit =
    fun data_vec (index, vec) ->
    match (data_vec, vec) with
    | (S.IntVec i, S.IntVec [|ri|]) -> Array.set i index ri
    | (S.FloatVec f, S.FloatVec [|rf|]) -> Array.set f index rf
    | (S.ComplexVec c, S.ComplexVec [|rc|]) -> Array.set c index rc
    | (S.StrVec s, S.StrVec [|rs|]) -> Array.set s index rs
    | (S.BoolVec b, S.BoolVec [|rb|]) -> Array.set b index rb
    (* TODO: better error messaging *)
    | (_, _) -> failwith "Badly-typed replacement, or too many things to replace"

let rvector_subset_assign: S.rvector -> int array -> int array list -> S.rvector -> unit =
    fun data data_dims subs assign ->
    match (data, assign) with
    | (S.IntVec id, S.IntVec ia) -> do_subset_assign_int (id, data_dims) subs ia
    | (S.FloatVec fd, S.FloatVec fa) -> do_subset_assign_float (fd, data_dims) subs fa
    | (S.ComplexVec cd, S.ComplexVec ca) -> do_subset_assign_complex (cd, data_dims) subs ca
    | (S.StrVec sd, S.StrVec sa) -> do_subset_assign_string (sd, data_dims) subs sa
    | (S.BoolVec bd, S.BoolVec ba) -> do_subset_assign_bool (bd, data_dims) subs ba
    | (_, _) -> failwith "Mismatched types in subset assign"

(* v[x] <- y *)
let subset_assign_mems: S.memref -> S.memref list -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref sub_refs assign_ref heap ->
    (* First, copy data, since we're going to edit it *)
    let data_ref', heap' = Copy.deep_copy data_ref heap in
    let assign_vec = C.dereference_rvector assign_ref heap' in
    let subs = sub_refs_to_subs sub_refs heap' in
    match S.heap_find data_ref' heap' with
    | Some (S.DataObj (S.Vec data_rvector, data_attributes)) ->
        let data_dims = get_dims data_attributes heap' in
        (* Changes the (copied) data rvector in-place *)
        let _ = rvector_subset_assign data_rvector data_dims subs assign_vec in
        (data_ref', heap')
    | _ -> failwith "Data is not a vector"

(* v[[x]] <- y *)
let subscript_assign_mems: S.memref -> S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref subscript_ref assign_ref heap ->
    let (data_ref', heap') = Copy.deep_copy data_ref heap in
    let assign_vec = C.dereference_rvector assign_ref heap' in
    match S.heap_find data_ref' heap' with
    | Some (S.DataObj (S.Vec data_rvec, data_attrs)) ->
        begin match C.dereference_rvector subscript_ref heap' with
        (* If the subscript is a string, need to look at names *)
        | S.StrVec subscript_vec -> let names_ref = begin
                match S.attrs_find (Some "names") data_attrs with
                | Some r -> r
                | None -> failwith "Cannot string subscript a vector with no names attribute"
                end in
            let names = C.rvector_to_str_array (C.dereference_rvector names_ref heap') in
            let idx = find_names_index names subscript_vec in
            let _ = do_replace data_rvec (idx, assign_vec) in
            (* No need to allocate - the copy already lives on the heap *)
            (data_ref', heap')
        (* If it's not a string, assume it's an int, and do normal integer subscripting *)
        | rvec -> let subscript_vec = C.rvector_to_int_array rvec in
            let idx = find_int_index (V.rvec_length data_rvec) (C.resolve_vec subscript_vec) in
            let _ = do_replace data_rvec (idx, assign_vec) in
            (data_ref', heap')
        end
    | _ -> failwith "Vector expected"

