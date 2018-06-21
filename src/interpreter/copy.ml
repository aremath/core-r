module S = Support
(* TODO: Current copying strategy goes into an infinite loop on cyclic pointer graphs.
Fortunately, I think that because R passes objects by deep copy, it's not possible to
create a cyclic pointer graph. *)
(*
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
*)

(* helper *)
let unzip_list: ('a * 'b) list -> 'a list * 'b list =
    fun zipped_list -> List.fold_right (fun (x, y) (al, bl) -> x::al, y::bl)
    zipped_list ([], [])

let copy_rvector: S.rvector -> S.rvector =
    function
    | S.IntVec v -> S.IntVec (Array.copy v)
    | S.FloatVec v -> S.FloatVec (Array.copy v)
    | S.ComplexVec v -> S.ComplexVec (Array.copy v)
    | S.StrVec v -> S.StrVec (Array.copy v)
    | S.BoolVec v -> S.BoolVec (Array.copy v)

(* converts an ident -> memref association list to a map.
Unfortunately not generalized over map types *)
let rec ident_map_of_alist: (S.ident * S.memref) list -> S.memref S.IdentMap.t -> S.memref S.IdentMap.t =
    fun idmems map ->
    match idmems with
    | (id, mem)::tl -> let map' = S.IdentMap.add id mem map in
            ident_map_of_alist tl map'
    | []    -> map

let rec string_map_of_alist: (S.rstring * S.memref) list -> S.memref S.RStringMap.t -> S.memref S.RStringMap.t =
    fun idmems map ->
    match idmems with
    | (id, mem)::tl -> let map' = S.RStringMap.add id mem map in
            string_map_of_alist tl map'
    | []    -> map

(* recursively copy the elements of a reference array *)
let rec copy_ref_array: S.memref list -> S.heap -> (S.memref list * S.heap) =
    fun mems heap ->
    match mems with
    | hd::tl    -> let (m', h') = deep_copy hd heap in
        let (ms, h'') = copy_ref_array tl h' in
        (m'::ms, h'')
    | []        -> ([], heap)

and copy_ident_map: S.memref S.IdentMap.t -> S.heap -> (S.memref S.IdentMap.t * S.heap) =
    fun map heap ->
    let bindings = S.IdentMap.bindings map in
    let (ids, mems) = unzip_list bindings in (* unzip bindings to get list of idents and mem refs *)
    let mems', heap' = copy_ref_array mems heap in (* deep copy the mems present in the map *)
    (* association list of ids, mems' *)
    let idmems = List.map2 (fun id mem -> (id, mem)) ids mems' in (* no need to copy ids *)
    let map' = ident_map_of_alist idmems S.IdentMap.empty in
    (map', heap')

and copy_string_map: S.memref S.RStringMap.t -> S.heap -> (S.memref S.RStringMap.t * S.heap) =
    fun map heap ->
    let bindings = S.RStringMap.bindings map in
    let (strs, mems) = unzip_list bindings in (* unzip bindings to get list of idents and mem refs *)
    let mems', heap' = copy_ref_array mems heap in (* deep copy the mems present in the map *)
    (* association list of ids, mems' *)
    let strmems = List.map2 (fun str mem -> (str, mem)) strs mems' in (* no need to copy ids *)
    let map' = string_map_of_alist strmems S.RStringMap.empty in
    (map', heap')

and copy_attributes: S.attributes -> S.heap -> (S.attributes * S.heap) =
    fun attrib heap ->
    let map', heap' = copy_string_map attrib.S.rstr_map heap in
    ({S.rstr_map = map'}, heap')

and copy_env: S.env -> S.heap -> (S.env * S.heap) =
    fun env heap ->
    let map', heap' = copy_ident_map env.S.mem_map heap in
    ({S.mem_map = map'; S.pred_mem = env.S.pred_mem}, heap') (* parent is shared *)

and copy_list: (S.ident option * S.memref) list -> S.heap -> ((S.ident option * S.memref) list * S.heap) =
    fun l heap ->
    let (ids, mems) = unzip_list l in 
    let mems', heap' = copy_ref_array mems heap in
    let idmems = List.map2 (fun id mem -> (id, mem)) ids mems' in (* no need to copy ids *)
    idmems, heap'

(* deep copy a memory reference *)
and deep_copy: S.memref -> S.heap -> (S.memref * S.heap) =
    fun mem heap ->
    let obj = try Some (S.MemRefMap.find mem heap.S.hobj_map) with Not_found -> None in
    match obj with
    | Some (S.PromiseObj _)   -> failwith "can't copy promises" (* TODO: force evaluation somehow? *)
    | Some (S.DataObj (v,a))    -> let (a', h') = copy_attributes a heap in
        begin match v with
        | S.Vec v         -> let alloc_obj = S.DataObj (S.Vec (copy_rvector v), a') in
            S.heap_alloc alloc_obj h'
        | S.RefArray v    -> let ms, h'' = copy_ref_array v h' in 
            let alloc_obj = S.DataObj ((S.RefArray ms), a') in
            S.heap_alloc alloc_obj h''
        | S.FuncVal _     -> mem, heap (* do not try to deepcopy functions *)
        | S.EnvVal v      -> let env, h'' = copy_env v h' in
            let alloc_obj = S.DataObj ((S.EnvVal env), a') in
            S.heap_alloc alloc_obj h''
        | S.ListVal v     -> let l, h'' = copy_list v h' in
            let alloc_obj = S.DataObj ((S.ListVal l), a') in
            S.heap_alloc alloc_obj h''
        end
    | None                  -> mem, heap (* can copy pointers with no associated memory for free *)


