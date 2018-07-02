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

(* TODO: does not return a memref (?) *)
let set_dims_mem: S.memref list -> S.heap -> S.heap =
    fun mems heap ->
    match mems with
    (* first, copy the reference to the dimension vector, since data will keep it *)
    | [data_ref;dim_ref] -> let dim_ref',heap' = Copy.deep_copy dim_ref heap in
    (* check if dims is compatible with data (product of dims == length of data) *)
        let dim_vec = C.resolve_vec (C.rvector_to_int_array (C.dereference_rvector dim_ref' heap')) in
        let data_len = rvec_length (C.dereference_rvector data_ref heap) in
        let dim_size = Array.fold_left (fun x y -> x * y) 1 dim_vec in
        if dim_size = data_len then
            match S.heap_find data_ref heap' with
            | Some (S.DataObj(_, attrs)) ->
                let _ = Hashtbl.replace attrs.S.rstr_map (Some "dim") dim_ref' in
                heap'
            | _ -> failwith "data missing in set_dims"
        else
            failwith "Dimension not compatible with vector length" (* TODO: sprintf to show what the size was *)
    | _ -> failwith "Bad call to set_dims"

(*
let concat_rvectors: S.rvector -> S.rvector -> S.rvector =
    fun v1 v2 ->
    match (v1, v2) with
    | ()
    | ()
    | ()
    | ()


(* Given n, make a1, a2, ..., an *)
let make_index_names: S.rstring -> int -> S.rstring array =
    fun str n ->
    Array.init n (fun i -> str ^ (string_of_int (i+1)))

(* From ("a", c(2,2)) to ("a1", "a2"), (2,2). Does not allocate the new rvectors *)
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

