(* Functions for dealing with rvectors - creating them, editing their attributes, etc. *)
module S = Support
module C = Native_support (* was Coerce *)
module Copy = Copy
module L = Langutils

let rvec_length: S.rvector -> int =
    function
    | S.IntVec i -> Array.length i
    | S.BoolVec b -> Array.length b
    | S.FloatVec f -> Array.length f
    | S.ComplexVec c -> Array.length c
    | S.StrVec s -> Array.length s

let rvec_length_mem: S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref heap ->
    let data_rvec = C.dereference_rvector data_ref heap in
    let len = rvec_length data_rvec in
    let len_vec = S.IntVec (Array.make 1 (Some len)) in
    (* allocate the length *)
    S.heap_alloc (S.DataObj (S.Vec len_vec, S.attrs_empty ())) heap

(* Returns a memref because of ex.
    y = (dim(x) <- c(1,5))  # y = [1, 5]
    TODO: do we need to copy dim_ref' again so that y here doesn't point directly to x's dims?
    I think it might be fine since there's no way to edit x's dims directly (anything will make a copy)
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
            let _ = S.attrs_add (Some "dim") dim_ref' attrs in
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
    (* | (S.SymVec s, pcs, S.IntVec i) -> S.SymVec (s', pcs') *)
    | _ -> failwith "Can't concatenate incompatible vectors"

let fold_rvectors: S.rvector list -> S.rvector =
    fun vlist ->
    match vlist with
    | [] -> failwith "Cannot fold empty rvectors list - type unknown"
    (* Determine the type based on the head. 
    concat_rvectors will throw an error if the types do not reconcile. *)
    | hd::tl -> begin match hd with
        | S.IntVec _ -> List.fold_left concat_rvectors (mk_empty_intvec ()) vlist
        | S.FloatVec _ -> List.fold_left concat_rvectors (mk_empty_floatvec ()) vlist
        | S.ComplexVec _ -> List.fold_left concat_rvectors (mk_empty_complexvec ()) vlist
        | S.StrVec _ -> List.fold_left concat_rvectors (mk_empty_strvec ()) vlist
        | S.BoolVec _ -> List.fold_left concat_rvectors (mk_empty_boolvec ()) vlist
        end

let alloc_fold_vectors: S.rvector list -> S.heap -> (S.memref * S.heap) =
    fun vecs heap ->
    match vecs with
    | [] -> (S.mem_null (), heap) (* Empty arrays are null *)
    (* TODO: this might cause bugs if you try to assign to an empty array's dims or something
    since there's no actual object. On the other hand, just Array.makeing a 0-length vector
    also doesn't have the right behavior *)
    (* Fold them with concat *)
    | _ -> let new_vec = fold_rvectors vecs in
        (* Allocate the new vector and return a reference to it *)
        S.heap_alloc (S.DataObj(S.Vec new_vec, S.attrs_empty ())) heap

(* Vector creation - R's "c" function *)
(* Does not support ex. c(a=c(1,2)) *)
let make_vector_simple_mems: S.memref list -> S.heap -> (S.memref * S.heap) =
    fun vec_mems heap ->
    (* First, deep copy the arguments so they're not captured *)
    let vec_mems', heap' = Copy.copy_ref_array vec_mems heap in
    (* Dereference the copies *)
    let vecs = List.map (fun m -> C.dereference_rvector m heap') vec_mems' in
    alloc_fold_vectors vecs heap'

(* Produces ex. (Some "a") 2 -> S.StrVec [| (Some "a1"), (Some "a2") |] *)
let n_names: S.rstring -> int -> S.rvector =
    fun so n ->
    match so with
    (* Empty string is for a vector that wasn't given a name as an argument.
    That means the names of all of its components in the final version will be "" *)
    | Some "" -> S.StrVec (Array.make n (Some ""))
    (* Non-empty string means that for n > 1, the names will be
     s ^ "1", s ^ "2", etc. *)
    | Some s -> if n = 1 then S.StrVec [|Some s|]
        else S.StrVec (Array.init n (fun i -> Some (s ^ (string_of_int (i + 1)))))
    (* None is invalid - variadic arguments will either not have a names attribute at all
     or have entries with "". Note that None is a valid value for an element of names in general,
     but it will never be passed in a call to make_vector. *)
    | None -> failwith "Invalid None name in n_names"

let make_vector_mems: S.memref -> S.heap -> (S.memref * S.heap) =
    fun var_mem heap ->
    (* First, copy the arguments since vector will capture them *)
    let var_mem', heap' = Copy.deep_copy var_mem heap in
    (* Dereference the variadic argument into a list of memrefs and the attrs *)
    let vec_mems, list_attrs = C.dereference_rlist_attrs var_mem' heap' in
    let vecs = List.map (fun m -> C.dereference_rvector m heap') vec_mems in
    begin match S.attrs_find (Some "names") list_attrs with
    (* names is a StrVec with one element per element of vec_mems 
     We need to unpack it so that it has one element per element of the fold of the vectors.
     This means converting the "a" in a=c(1,2) to "a1,a2" *)
    | Some (arg_names_ref) -> let arg_names_list = Array.to_list
            (C.rvector_to_str_array (C.dereference_rvector arg_names_ref heap')) in
        let vec_lengths = List.map (fun v -> rvec_length v) vecs in
        let n_names_list = List.map2 n_names arg_names_list vec_lengths in
        (* Fold the new names vectors into a single names and allocate it *)
        let names_ref, heap'' = alloc_fold_vectors n_names_list heap' in
        (* Fold the data vectors and into a single data and allocate it *)
        let vec_ref, heap''' = alloc_fold_vectors vecs heap'' in
        (* It's clunky, but we're going to dereference the newly-allocated vec_ref
         to bind it's attributes and create the names attribute. *)
        let _ = begin match S.heap_find vec_ref heap''' with
        | Some (S.DataObj (_, vec_attrs)) -> S.attrs_add (Some "names") names_ref vec_attrs
        | _ -> failwith "That should not have happened!!!"
        end in
        (* The return reference is to the resulting vector *)
        vec_ref, heap'''
    (* No names means we're just supposed to fold the vectors together like usual.
      The resulting rvector has attrs_empty *)
    | None -> alloc_fold_vectors vecs heap'
    end

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
    S.heap_alloc (S.DataObj (S.Vec out_rvec, S.attrs_empty ())) heap

(* Need to do this pattern matching because of how rvector is defined *)
let rvector_length: S.rvector -> int =
    fun vec ->
    match vec with
    | S.IntVec i -> Array.length i
    | S.FloatVec f -> Array.length f
    | S.ComplexVec c -> Array.length c
    | S.StrVec s -> Array.length s
    | S.BoolVec b -> Array.length b

(* makes an array which is a copied n times *)
let rec array_wrap: 'a array -> int -> 'a array =
    fun a n ->
    (* Wrap once just means copy *)
    if n = 1 then Array.copy a
    (* Wrap more than once means append a copy of a onto the rest of the wrap *)
    else (Array.concat ( (Array.copy a)::[(array_wrap a (n-1))]))

(* TODO: can accomplish the same result with iteration
 and having each vector modulo the iterator by their length.
 Doesn't let us use the current setup, but definitely saves
 time copying things. Then again when has R ever cared about
 saving time copying things? :) *)
(* Wraps an rvector n times *)
let rvector_wrap: S.rvector -> int -> S.rvector =
    fun v n ->
    match v with
    | S.IntVec i -> S.IntVec (array_wrap i n)
    | S.FloatVec f -> S.FloatVec (array_wrap f n)
    | S.ComplexVec c -> S.ComplexVec (array_wrap c n)
    | S.StrVec s -> S.StrVec (array_wrap s n)
    | S.BoolVec b -> S.BoolVec (array_wrap b n)

(* Vector binary operations - suitable functions to pass found in arithmetic.ml *)
(* TODO: does this function need to copy the arguments? *)
let vector_bop_mems: (S.rvector -> S.rvector -> S.rvector) ->
                     S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun binop lhs_ref rhs_ref heap ->
    let lhs = C.dereference_rvector lhs_ref heap in
    let rhs = C.dereference_rvector rhs_ref heap in
    (* Multiply out the shorter rvector, if appropriate *)
    let (true_rhs, true_lhs) = let l_length = rvector_length lhs in
        let r_length = rvector_length rhs in
        (* If their lengths match, then no extension is necessary *)
        if l_length = r_length then (lhs, rhs)
        (* Otherwise, check that their lengths are compatible
        (one is a multiple of the other) *)
        else if (l_length < r_length) && (r_length mod l_length = 0) then
            let n = r_length / l_length in
            (rvector_wrap lhs n, rhs)
        else if (l_length > r_length) && (l_length mod r_length = 0) then
            let n = l_length / r_length in
            (lhs, rvector_wrap rhs n)
        else failwith "Can't add vectors with incompatible lengths"
    in
    (* Do the operation on the (possibly wrapped) vectors *)
    let new_vec = binop true_rhs true_lhs in
    (* Allocate the result! *)
    (* TODO: is attrs_empty () appropriate? *)
    S.heap_alloc (S.DataObj ((S.Vec new_vec), S.attrs_empty ())) heap

(* Inefficient, but works *)
let array_filter: ('a -> bool) -> 'a array -> 'a array =
    fun pred a ->
    let l = List.filter pred (Array.to_list a) in
    Array.of_list l

let drop_dims_mems: S.memref -> S.heap -> (S.memref * S.heap) =
    fun vec_ref heap ->
    (* First, copy the argument *)
    let vec_ref', heap' = Copy.deep_copy vec_ref heap in
    match S.heap_find vec_ref heap with
    | Some (S.DataObj (S.Vec v, attrs)) ->
        begin match S.attrs_find (Some "dim") attrs with
        | Some dim_ref -> let dim_vec = C.dereference_rvector dim_ref heap in
            let dim_array = C.rvector_to_int_array dim_vec in
            let new_dim_array = array_filter (fun i -> i = Some 1) dim_array in
            (* Allocate the new dims *)
            let (dim_ref', heap'') = S.heap_alloc
                (S.DataObj (S.Vec (S.IntVec new_dim_array), S.attrs_empty ())) heap' in
            (* Replace attrs' dim mapping *)
            let _ = S.attrs_add (Some "dim") dim_ref' attrs in
            (* TODO: what is this supposed to return? *)
            (dim_ref', heap'')
        (* No dims means nothing to drop *)
        | None -> (vec_ref', heap')
        end
    | Some _ -> failwith "DropDims: Data not a vector!"
    | None -> failwith "DropDims: Data vector not found!"

(* For use with ex. C.rvector_as_integer. Assumes that the conversion function
 will correctly copy the vector (?) *)
let convert_vector_mems: (S.rvector -> S.rvector) -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun convert_fun vec_ref heap ->
    (* Dereference it *)
    let rvec = C.dereference_rvector vec_ref heap in
    (* Convert it *)
    let convert = convert_fun rvec in
    (* Allocate it *)
    (* TODO: when does type conversion keep attributes? *)
    S.heap_alloc (S.DataObj (S.Vec (convert), S.attrs_empty ())) heap

(* Helper for v *)
let array_length_assign: 'a option array -> int -> 'a option array =
    fun a n ->
    Array.init n (fun i -> if i < Array.length a then a.(i) else None)

(* Return an rvector with length len. If len is longer than vec, fills with NA,
if len is shorter than vec, only uses the first len values *)
let rvec_length_assign: S.rvector -> int -> S.rvector =
    fun vec len ->
    match vec with
    | S.IntVec i -> S.IntVec (array_length_assign i len)
    | S.FloatVec f -> S.FloatVec (array_length_assign f len)
    | S.ComplexVec c -> S.ComplexVec (array_length_assign c len)
    | S.StrVec s -> S.StrVec (array_length_assign s len)
    | S.BoolVec b -> S.BoolVec (array_length_assign b len)
    
(* TODO: for this to work properly, the preprocessor needs to translate 
 length(x) = 12 as x = length<-(x, 12) rather than just length<-(x,12) *)
(* length<- *)
let vector_length_assign_mems: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref len_ref heap ->
    let data_vec = C.dereference_rvector data_ref heap in
    let len = match C.get_single_rint len_ref heap with
    | Some i -> i (* TODO: R fails with length<-c(2,2), but this will merely warning *)
    | None -> failwith "NA invalid in length<-" in
    let new_rvec = rvec_length_assign data_vec len in
    (* Allocate it *)
    S.heap_alloc (S.DataObj (S.Vec (new_rvec), S.attrs_empty ())) heap

(* Helper for list_ref_length. Errors out if vec_ref points to anything other than
 a StrVec with length 1. *)
let assert_len1_strvec: S.memref -> S.heap -> unit =
    fun vec_ref heap ->
    (* dimnames can contain NAs, otherwise match [|Some s|] *)
    match C.dereference_rvector vec_ref heap with
    | S.StrVec [|s|] -> ()
    | _ -> failwith "Invalid reference in list_ref_length."

(* Helper for list_dims_mems. Finds the "length" of a reference. In this case,
 Because dimnames is a list of lists or literal values, will produce an error if
 the reference is to anything other than a length 1 string vector or to a list *)
(* NOTE: R will coerce vectors in dimnames to lists - SimpleR will not. *)
let list_ref_length: S.memref -> S.heap -> int =
    fun list_ref heap ->
    match S.heap_find list_ref heap with
    (* Matches only a stringvec with length 1 *)
    | Some (S.DataObj (S.Vec (S.StrVec [|s|]), _)) -> 1
    | Some (S.DataObj (S.RefArray l, _)) ->
        (* Assert that each element of the list is a single string. *)
        let _ = List.iter (fun ref -> assert_len1_strvec ref heap) l in
        List.length l
    | _ -> failwith "Invalid reference in list_ref_length."

(* Create the implied dims for a list - If the dims produced by this is the same
 as the actual dims for a vector, then this list is a valid dimnames *)
let list_dims_mems: S.memref -> S.heap -> int array =
    fun list_ref heap ->
    let lst = match S.heap_find list_ref heap with
    | Some (S.DataObj (S.RefArray l, _)) -> l
    | _ -> failwith "List not found" in
    let out_array = Array.make (List.length lst) 0 in
    (* Assign to out_array the calculated length of each reference *)
    let _ = List.iteri (fun i lref -> out_array.(i) <- list_ref_length lref heap) lst in
    out_array

(* Compare two int arrays for equality *)
let compare_dims: int array -> int array -> bool =
    fun dims1 dims2 ->
    (* Want each element to be equal *)
    Array.fold_left (&&) true
        (* The array of bools, whether dims1[i] = dims2[i] *)
        (C.array_map2 (=) dims1 dims2)

(* dimnames<- *)
let vector_dimnames_assign_mems: S.memref -> S.memref -> S.heap -> (S.memref * S.heap) =
    fun data_ref dimnames_ref heap ->
    (* Dimnames must be a LIST whose extent matches the dim attribute of the data.
     ex. If x has dims c(3,3,3), then the dimnames passed here must be a list of three lists,
     each with length three. Note that slicing a vector should also slice its dimnames (TODO) *)
    (* First, copy data and dimnames - data's attrs are edited, and dimnames is captured *)
    let data_ref', heap' = Copy.deep_copy data_ref heap in
    let dimnames_ref', heap'' = Copy.deep_copy dimnames_ref heap' in
    begin match S.heap_find data_ref' heap'' with
    | Some (S.DataObj (S.Vec v, data_attrs)) ->
        (* First get the dims to figure out what lengths dimnames has to satisfy *)
        begin match S.attrs_find (Some "dim") data_attrs with
        | Some (dim_ref) -> let dim_vec = C.resolve_vec 
                (C.rvector_to_int_array (C.dereference_rvector dim_ref heap'')) in
            (* Check that dimnames has the right length *)
            let dimnames_dim_vec = list_dims_mems dimnames_ref' heap in
            let _ = if compare_dims dim_vec dimnames_dim_vec then ()
                else failwith "Dimnames not compatible with dims" in
            (* Put dimnames into data's attrs *)
            let _ = S.attrs_add (Some "dimnames") dimnames_ref' data_attrs in
            (* Return a reference to dimnames and the heap with the copies *)
            (* TODO: Same issue here as with dim<- : does the returned reference need to be a second copy? *)
            (dimnames_ref', heap'')
        | None -> failwith "data has no dim attribute"
        end
    | _ -> failwith "Missing data or data not a vec in dimnames assignment"
    end

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
        let dims_ref, heap''' = heap_alloc (S.DataObj (S.IntVec dims, attrs_empty ())) heap'' in

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

