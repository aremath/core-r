module S = Support
module C = Copy

let dereference_rvector: S.memref -> S.heap -> S.rvector =
    fun mem heap ->
    match S.MemRef_Map.find mem heap with
    | DataObj (Vec v, _) -> v
    | _ -> failwith "Vec expected in dereference"

(* TODO: catch a dereference error somehow? *)
let dereference: S.memref list -> S.heap -> S.heapobj list =
    fun mems heap ->
    List.map (fun mem -> S.MemRef_Map.find mem heap) mems

let vector_length: (S.rvector * S.attributes) -> (S.rvector * S.attributes) =
    fun (vec, attrs) ->
    let make_length_vec = fun v -> Array.make 1 (Some (Array.length v)) in
    match vec with
    | S.RIntVec v -> (make_length_vec v, S.attrs_empty)
    | S.RBoolVec v -> (make_length_vec v, S.attrs_empty)
    | S.RFloatVec v -> (make_length_vec v, S.attrs_empty)
    | S.RComplexVec v -> (make_length_vec v, S.attrs_empty)
    | S.RStringVec v -> (make_length_vec v, S.attrs_empty)

let do_matrix_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun args heap ->
    match args with
    | [data_ref;nrows_ref;ncols_ref;byrow_ref;dimnames_ref] ->
        (* copy data, dimnames *)
        let data_ref', heap' = C.deep_copy data_ref heap in
        let dimnames_ref', heap'' = C.deep_copy dimnames_ref heap' in

        (* dereference data that is not assigned to *)
        let nrows = dereference_rvector nrows_ref heap in
        let ncols = dereference_rvector ncols_ref heap in
        let byrow = dereference_rvector byrow_ref heap in
        let old_data  = dereference_rvector data_ref' heap in

        (* Create and allocate the new dims *)
        let dims = get_dims old_data nrows ncols in
        let dims_ref, heap''' = heap_alloc (S.DataObj (S.IntVec dims, attrs_empty)) heap'' in

        (* Add dim and dimnames to the new vector's attrs *)
        (* TODO: want to mutably access data attributes without reallocating the object *)
        let new_data, data_attrs = match S.MemRef_Map.find data_ref' heap''' with
        | S.DataObj(d, a) -> (d, a)
        | _ -> failwith "invalid attributes in do_matrix"
        in
        let _ = S.attrs_add "dim" dims_ref data_attrs
        let _ = S.attrs_add "dimnames" dimnames_ref' data_attrs in
        (* Rearrange the new vector according to dims *)
        let _ = rearrange_vec new_data byrow dims in
        (* return the copied vector and the heap with dims allocated *)
        (data_ref', heap''')
    | _ -> failwith "bad call to do_matrix" (* wrong number of arguments *)

(* assumes defaults have been taken care of *)
let get_dims: rvector -> rvector -> rvector -> rvector -> rlist -> rvector =
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

(* removes unnecessary dimensions from the rvector *)
(* TODO: should be (memref list/array) -> heap -> (memref * heap) *)
let drop_dims: (rvector * attributes) -> (rvector * attributes) =
    fun (vec, attrs) ->
    let dims_opt = attrs_find "dim" attrs in
    match dims_opt with
    | None -> (vec, attrs) (* no change to attrs is needed *)
    | Some dim_ref -> (* dereference! *)
