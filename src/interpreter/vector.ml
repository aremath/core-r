
type rlist = list

type rvector = 
    | RIntVec of rint Array
    | RBoolVec of rbool Array
    | RFloatVec of rfloat Array
    | RComplexVec of rcomplex Array
    | RStringVec of rstring Array

type rmatrix = (rvector * int Array * string Array Array option)

(* TODO: mutable things will be /physically/ equivalent... is this ok? *)
let copy_vector: rvector -> rvector = function
    | RIntVec v -> RIntVec (Array.copy v)
    | RBoolVec v -> RBoolVec (Array.copy v)
    | RFloatVec v -> RFloatVec (Array.copy v)
    | RComplexVec v -> RCompplexVec (Array.copy v)
    | RStringVec v -> RStringVec (Array.copy v)

(* TODO: need to do a deeper copy? *)
let copy_matrix: rmatrix -> bool -> rmatrix = 
    fun m byrow ->
    match m with
    | v, dims, opt_dimnames -> if byrow then
        let new_array = copy_vector v in (* TODO: inefficient to copy if I'm just going to overwrite *)
        let nr = dims.(0) in
        let nc = dims.(1) in
        let _ = for x = 0 to nr - 1 do
            for y = 0 to nc - 1 do
                new_array.(x + y*nr) <- v.(x*nc + y)
            done
        done in
        new_array
        (* TODO: need to deep copy dimnames? *)
        else match opt_dimnames with
        | Some dimnames -> (copy_vector v, Array.copy dims, Array.copy dimnames)
        | None -> (copy_vector v, Array.copy dims, None)

let vector_length: rvector -> rvector = function
    let make_length_vec = fun v -> Array.make 1 (Some (Array.length v))
    | RIntVec v -> make_length_vec v
    | RBoolVec v -> make_length_vec v
    | RFloatVec v -> make_length_vec v
    | RComplexVec v -> make_length_vec v
    | RStringVec v -> make_length_vec v

(* assumes defaults have been taken care of *)
(* TODO: do_matrix can also take a list! *)
let do_matrix: rvector -> rvector -> rvector -> rvector -> rlist -> rmatrix =
    fun data nrows ncols byrow dimnames ->
    let bool_byrow = match byrow.(0) with
    | Some 0   -> false
    | Some 1   -> true
    | _        -> failwith "invalid byrow argument" in
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
    let array_dims = Array.make 2 0 in
    let _ = array_dims.(0) <- true_nr in
    let _ = array_dims.(1) <- true_nc in
    matrix_copy (data, array_dims, None) bool_byrow
    

