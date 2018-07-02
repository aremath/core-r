module S = Support
module C = Coerce
module Copy = Copy

let rvec_length: S.rvector -> int =
    function
    | S.IntVec i -> Array.length i
    | S.BoolVec b -> Array.length b
    | S.FloatVec f -> Array.length f
    | S.ComplexVec c -> Array.length c
    | S.StrVec s -> Array.length s

(* Returns a memref because of ex.
    y = (dim(x) <- c(1,5))  # y = [1, 5]
    TODO: do we need to copy dim_ref' again so that y here doesn't point directly to x's dims?
*)
let set_dims_mem: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref dim_ref heap ->
    (* first, copy the reference to the dimension vector, since data will keep it *)
    let dim_ref',heap' = Copy.deep_copy dim_ref heap in
    (* check if dims is compatible with data (product of dims == length of data) *)
    let dim_vec = C.resolve_vec (C.rvector_to_int_array (C.dereference_rvector dim_ref' heap')) in
    let data_len = rvec_length (C.dereference_rvector data_ref heap) in
    let dim_size = Array.fold_left (fun x y -> x * y) 1 dim_vec in
    if dim_size = data_len then
        match S.heap_find data_ref heap' with
        | Some (S.DataObj(_, attrs)) ->
            let _ = Hashtbl.replace attrs.S.rstr_map (Some "dim") dim_ref' in
            (dim_ref', heap')
        | _ -> failwith "Data missing in set_dims"
    else
        failwith "Dimension not compatible with vector length" (* TODO: sprintf to show what the size was *)

let mk_empty_intvec: unit -> S.rvector = fun _ -> S.IntVec (Array.make 0 (Some 0))
let mk_empty_floatvec: unit -> S.rvector = fun _ -> S.FloatVec (Array.make 0 (Some 0.0))
let mk_empty_complexvec: unit -> S.rvector = fun _ -> S.ComplexVec (Array.make 0 (Some Complex.zero))
let mk_empty_strvec: unit -> S.rvector = fun _ -> S.StrVec (Array.make 0 (Some ""))
let mk_empty_boolvec: unit -> S.rvector = fun _ -> S.BoolVec (Array.make 0 (Some 0))

(* Concatenate two vectors - For now does not do type coercion *)
let concat_rvectors: S.rvector -> S.rvector -> S.rvector =
    fun v1 v2 ->
    match (v1, v2) with
    | (S.IntVec i1, S.IntVec i2) -> S.IntVec (Array.concat [i1;i2])
    | (S.FloatVec f1, S.FloatVec f2) -> S.FloatVec (Array.concat [f1;f2])
    | (S.ComplexVec c1, S.ComplexVec c2) -> S.ComplexVec (Array.concat [c1;c2])
    | (S.StrVec s1, S.StrVec s2) -> S.StrVec (Array.concat [s1;s2])
    | (S.BoolVec b1, S.BoolVec b2) -> S.BoolVec (Array.concat [b1;b2])
    | _ -> failwith "Can't concatenate incompatible vectors"

let fold_rvectors: S.rvector list -> S.rvector =
    fun vlist ->
    match vlist with
    | [] -> failwith "Cannot fold empty rvectors list - no type known"
    (* Determine the type based on the head. 
    concat_rvectors will throw an error if the types do not reconcile. *)
    | hd::tl -> begin match hd with
        | S.IntVec _ -> List.fold_left concat_rvectors (mk_empty_intvec ()) vlist
        | S.FloatVec _ -> List.fold_left concat_rvectors (mk_empty_floatvec ()) vlist
        | S.ComplexVec _ -> List.fold_left concat_rvectors (mk_empty_complexvec ()) vlist
        | S.StrVec _ -> List.fold_left concat_rvectors (mk_empty_strvec ()) vlist
        | S.BoolVec _ -> List.fold_left concat_rvectors (mk_empty_boolvec ()) vlist
        end

(* Vector creation - R's "c" function *)
(* Does not support ex. c(a=c(1,2)) *)
let make_vector_simple_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun vec_mems heap ->
    (* First, deep copy the arguments so they're not captured *)
    let vec_mems', heap' = Copy.copy_ref_array vec_mems heap in
    (* Dereference the copies *)
    let vecs = List.map (fun m -> C.dereference_rvector m heap') vec_mems' in
    match vecs with
    | [] -> (S.mem_null, heap) (* Empty arrays are null *)
    (* TODO: this might cause bugs if you try to assign to an empty array's dims or something
    since there's no actual object. On the other hand, just Array.makeing a 0-length vector
    also doesn't have the right behavior *)
    (* Fold them with concat *)
    | _ -> let new_vec = fold_rvectors vecs in
        (* Allocate the new vector and return a reference to it *)
        S.heap_alloc (S.DataObj(S.Vec new_vec, S.attrs_empty)) heap'

(* Heavy lifting for range - creates a range of integers from start to end as an array *)
let int_range: int -> int -> int array =
    fun start_index end_index ->
    (* How many elements the array will have *)
    let n = (abs (end_index - start_index)) + 1 in
    (* Increasing or decreasing? *)
    let step = if start_index < end_index then 1 else -1 in
    Array.init n (fun i -> start_index + (i * step))

(* Same as ^ but for floats *)
let float_range: float -> float -> float array =
    fun startf endf ->
    (* How many elements the array will have *)
    let n = int_of_float (floor (abs_float (startf -. endf))) + 1 in
    let step = if startf < endf then 1.0 else -1.0 in
    Array.init n (fun i -> startf +. ((float_of_int i) *. step))

(* Handles 1:5 and 5:-5. TODO: 1.3:2.6 *)
let range_int_mems: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun start_index_ref end_index_ref heap ->
    let start_index = match C.get_single_rint start_index_ref heap with
    | Some i -> i
    | None -> failwith "NA in range" in
    let end_index = match C.get_single_rint end_index_ref heap with
    | Some i -> i
    | None -> failwith "NA in range" in
    (* Dereference the vectors down to rvectors *)
    let start_rvec = C.dereference_rvector start_index_ref heap in
    let end_rvec = C.dereference_rvector end_index_ref heap in
    (* Match to determine output vector type *)
    let out_rvec = match start_rvec, end_rvec with
    | (S.IntVec [|Some si|], S.IntVec [|Some ei|]) -> let irange = int_range si ei in
        S.IntVec (C.unresolve_vec irange)
    | (S.FloatVec [|Some sf|], S.FloatVec [|Some ef|]) -> let frange = float_range sf ef in
        S.FloatVec (C.unresolve_vec frange)
    | _ -> failwith "Bad range call" in (* TODO: better error messaging *)
    S.heap_alloc (S.DataObj (S.Vec out_rvec, S.attrs_empty)) heap

(*
(* Given n, make a1, a2, ..., an *)
let make_index_names: S.rstring -> int -> S.rstring array =
    fun str n ->
    Array.init n (fun i -> str ^ (string_of_int (i+1)))

(* From ("a", c(2,2)) to ("a1", "a2"), (2,2). Does not allocate the rvectors *)
let make_vector_help: (S.rstring * S.memref) -> S.heap -> (S.rvector * S.rvector) =
    fun (str, mem) -> let mem_vec = dereference_rvector mem heap in
    let indices = make_index_names (rvec_length mem_vec) in
    (indices, mem_vec)

(* does make vector help for each vector, and concatenates them *)
let make_vector: (S.ident option * S.memref) list -> heap -> (S.rvector * S.rvector) =
    fun l heap ->
    List.map

(*let make_vector_mems: S.memref list -> heap -> (memref * heap)*)

*)


(*
(* assumes defaults have been taken care of *)
let get_dims: S.rvector -> S.rvector -> S.rvector -> S.rvector =
    fun data nrows ncols ->
    let int_nr = match nrows.(0) with
    | Some x    -> x
    | None      -> failwith "invalid nrows argument" in
    let int_nc = match ncols.(0) with
    | Some x    -> x
    | None      -> failwith "invalid ncols argument" in
    let len = Array.length data in
    let true_nr =
    match int_nr with
    | -1    -> begin match int_nc with
                | -1    -> len
                | 0     -> if len > 0 then failwith "nc = 0 for non-null data"
                    else 0
                | x     -> let xf = float_of_int x in
                    let lenf = float_of_int len in
                    int_of_float (ciel (lenf /. xf))
                end
    | x     ->  x in
    let true_nc =
    match int_nc with
    | -1    -> begin match true_nr with
                | 0 -> if len > 0 then failwith "nr = 0 for non-null data"
                    else 0
                | x -> let xf = float_of_int x in
                    let lenf = float_of_int len in
                    int_of_float (ciel (lenf /. xf))
                end
    | x     -> x in
    (* does the data fit into an nr * nc matrix? *)
    let _ = if len > 0 then
        let nrc = true_nr * true_nc in
        if (len > 1) && (nrc mod len <> 0) then
            if ((len > true_nr) && (len / true_nr) * true_nr <> len) ||
                ((len < true_nr && (true_nr / len) * len <> true_nr)) then
                failwith "data length is not a sub-multiple of the number of rows"
            else if ((len > nc) && (len / true_nc) * true_nc <> len) ||
                ((len < nc) && (true_nc / len) <> true_nc) then
                failwith "data length is not a sub-multiple of the number of columns"
            else ()
        else if (len > 1) && (nrc = 0) then failwith "data length exceeds matrix size"
        else ()
    else () in
    let matrix_dims = Array.make 2 (Some 0) in
    let _ = matrix_dims.(0) <- true_nr in
    let _ = matrix_dims.(1) <- true_nc in
    matrix_dims

let do_matrix_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun args heap ->
    match args with
    | [data_ref;nrows_ref;ncols_ref;byrow_ref;dimnames_ref] ->
        (* copy data, dimnames *)
        let data_ref', heap' = Copy.deep_copy data_ref heap in
        let dimnames_ref', heap'' = Copy.deep_copy dimnames_ref heap' in

        (* dereference data that is not assigned to *)
        let nrows = C.dereference_rvector nrows_ref heap in
        let ncols = C.dereference_rvector ncols_ref heap in
        let byrow = C.dereference_rvector byrow_ref heap in
        let old_data  = C.dereference_rvector data_ref' heap in

        (* Create and allocate the new dims *)
        let dims = get_dims old_data nrows ncols in
        let dims_ref, heap''' = heap_alloc (S.DataObj (S.IntVec dims, attrs_empty)) heap'' in

        (* Add dim and dimnames to the new vector's attrs *)
        (* TODO: want to mutably access data attributes without reallocating the object *)
        let new_data, data_attrs = match S.MemRef_Map.find data_ref' heap''' with
        | S.DataObj(d, a) -> (d, a)
        | _ -> failwith "invalid attributes in do_matrix"
        in
        let _ = S.attrs_add "dim" dims_ref data_attrs in
        let _ = S.attrs_add "dimnames" dimnames_ref' data_attrs in
        (* Rearrange the new vector according to dims *)
        let _ = rearrange_vec new_data byrow dims in
        (* return the copied vector and the heap with dims allocated *)
        (data_ref', heap''')
    | _ -> failwith "bad call to do_matrix" (* wrong number of arguments *)
*)

(* (* removes unnecessary dimensions from the rvector *)
(* TODO: should be (memref list/array) -> heap -> (memref * heap) *)
let drop_dims: (rvector * attributes) -> (rvector * attributes) =
    fun (vec, attrs) ->
    let dims_opt = attrs_find "dim" attrs in
    match dims_opt with
    | None -> (vec, attrs) (* no change to attrs is needed *)
    | Some dim_ref -> (* dereference! *)
*)

