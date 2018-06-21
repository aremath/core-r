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

let zip_list: 'a list -> 'b list -> ('a * 'b) list =
    fun l1 l2 -> List.map2 (fun x y -> (x,y)) l1 l2

let hashtable_to_alist: ('a, 'b) Hashtbl.t -> ('a * 'b) list =
    fun hashtable ->
    Hashtbl.fold (fun k v l -> (k,v)::l) hashtable []

let alist_to_hashtable: ('a * 'b) list -> ('a, 'b) Hashtbl.t =
    fun alist ->
        let h = Hashtbl.create (List.length alist) in (* TODO: default value? *)
        let _ = List.iter (fun (k, v) -> Hashtbl.add h k v) alist in
        h

(* deep copy and associated functions *)
let copy_rvector: S.rvector -> S.rvector =
    function
    | S.IntVec v -> S.IntVec (Array.copy v)
    | S.FloatVec v -> S.FloatVec (Array.copy v)
    | S.ComplexVec v -> S.ComplexVec (Array.copy v)
    | S.StrVec v -> S.StrVec (Array.copy v)
    | S.BoolVec v -> S.BoolVec (Array.copy v)

(* recursively copy the elements of a reference list *)
let rec copy_ref_array: S.memref list -> S.heap -> (S.memref list * S.heap) =
    fun mems heap ->
    match mems with
    | hd::tl    -> let (m', h') = deep_copy hd heap in
        let (ms, h'') = copy_ref_array tl h' in
        (m'::ms, h'')
    | []        -> ([], heap)

(* copy an associative list of keys to memory references *)
and copy_alist:'a. ('a * S.memref) list -> S.heap -> ('a * S.memref) list * S.heap =
    fun alist heap ->
    let keys, mems = unzip_list alist in
    let mems', heap' = copy_ref_array mems heap in
    ((zip_list keys mems'), heap) (* no need to copy keys *)

and copy_env: S.env -> S.heap -> (S.env * S.heap) =
    fun env heap ->
    let bindings = S.IdentMap.bindings env.S.mem_map in
    let idmems, heap' = copy_alist bindings heap in
    let env' = S.env_add_list idmems S.env_empty in
    let env'' = {env' with S.pred_mem = env.S.pred_mem} in (* parent is shared *)
    (env'', heap')

and copy_attributes: S.attributes -> S.heap -> (S.attributes * S.heap) =
    fun attrib heap ->
    let attr_alist = hashtable_to_alist attrib.S.rstr_map in
    let attr_alist', heap' = copy_alist attr_alist heap in
    let new_table = alist_to_hashtable attr_alist' in (* can use S.attrs_add_list too *)
    ({S.rstr_map = new_table}, heap')

and copy_list: (S.ident option * S.memref) list -> S.heap -> ((S.ident option * S.memref) list * S.heap) =
    fun l heap ->
    let (ids, mems) = unzip_list l in 
    let mems', heap' = copy_ref_array mems heap in
    let idmems = zip_list ids mems' in
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


