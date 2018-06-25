open Support
module L = Langutils

let string_of_memref: memref -> string =
    fun mem ->
    "MEM*" ^ (string_of_int mem.R.addr)

let string_of_env: env -> string =
    fun env ->
    let ident_map_alist = IdentMap.bindings env.id_map in
    let ident_map_strs = List.map (fun (ident, memref) -> 
        (L.string_of_ident ident) ^ ":\t" ^ (string_of_memref memref)) ident_map_alist in
    "ENV:\n" ^
    "Parent: " ^ (string_of_memref env.pred_mem) ^ "\n" ^
    (String.concat "\n"  ident_map_strs) ^ "\n"

let string_of_rstring: rstring -> string =
    function
    | Some s -> "\"" ^ s ^ "\""
    | None -> "NaString"

let string_of_rint: rint -> string =
    function
    | Some i -> (string_of_int i)
    | None -> "NaInt"

let string_of_rfloat: rfloat -> string =
    function
    | Some f -> (string_of_float f)
    | None -> "NaFloat"

let string_of_rcomplex: rcomplex -> string =
    function
    | Some c -> "Complex(" ^ (string_of_float c.Complex.re) ^ ", " ^
        (string_of_float c.Complex.im) ^ ")"
    | None -> "NaComplex"

let string_of_rbool: rbool -> string =
    function
    | Some b -> if b == 1 then "True" else "False"
    | None -> "NaBool"

let string_of_rvector: rvector -> string =
    function
    | IntVec i -> String.concat ", " (List.map (fun x -> string_of_rint x) (Array.to_list i))
    | FloatVec f -> String.concat ", " (List.map (fun x -> string_of_rfloat x) (Array.to_list f))
    | ComplexVec c -> String.concat ", " (List.map (fun x -> string_of_rcomplex x) (Array.to_list c))
    | StrVec s -> String.concat ", " (List.map (fun x -> string_of_rstring x) (Array.to_list s))
    | BoolVec b -> String.concat ", " (List.map (fun x -> string_of_rbool x) (Array.to_list b))

let string_of_attributes: attributes -> string =
    fun attrs ->
    let a_str = Hashtbl.fold (fun k v base -> 
            (string_of_rstring k) ^ (string_of_memref v) ^ "\n" ^ base) attrs.rstr_map "" in
    "Attrs:\n" ^ a_str

let string_of_value: value -> string =
    function
    | Vec v -> "[" ^ (string_of_rvector v) ^ "]"
    | RefArray ms -> "MEMS[" ^ (String.concat ", " (List.map (fun x -> (string_of_memref x)) ms)) ^ "]"
    | FuncVal (params, expr, mem) -> let mem_str = string_of_memref mem in
        let params_strs = List.map (fun x -> L.string_of_param x) params in
        let expr_str = L.string_of_expr expr in
        "Function:" ^
        "\n\tParams:\t" ^ (String.concat "\n\t" params_strs) ^
        "\n\tExpr:\t" ^ expr_str ^
        "\n\tMem:\t" ^ mem_str ^ "\n"
    | EnvVal e -> string_of_env e
    | ListVal l -> let list_strs = (List.map (fun (iopt,mem) ->
            match iopt with
            | Some i -> (L.string_of_ident i) ^ " = " ^ (string_of_memref mem)
            | None  -> (string_of_memref mem)) l) in
            "List:\n" ^
            (String.concat "\n" list_strs) ^ "\n"

let string_of_heapobj: heapobj -> string = 
    function
    | PromiseObj (e, m) ->
        "Promise:" ^
        "\n\te:" ^ (L.string_of_expr e) ^
        "\n\tm: " ^ (string_of_memref m) ^ "\n"
    | DataObj (v, a) ->
        "Data:" ^
        "\n\tvalue:\t" ^ (string_of_value v) ^
        "\n\tattrs:\t" ^ (string_of_attributes a) ^ "\n"

let string_of_heap: heap -> string =
    fun heap ->
    let mem_map_alist = MemRefMap.bindings heap.mem_map in
    let mem_map_strs = List.map (fun (memref, heapobj) ->
        (string_of_memref memref) ^ ":\t" ^ (string_of_heapobj heapobj)) mem_map_alist in
    "HEAP:\n" ^
    "Next: " ^ (string_of_memref heap.next_mem) ^ "\n" ^
    (String.concat "\n" mem_map_strs) ^ "\n"

let string_of_slot: slot -> string =
    function
    | ReturnSlot m -> "Return " ^ (string_of_memref m)
    | UpdateSlot m -> "Update " ^ (string_of_memref m)
    | EvalSlot e -> "Evaluate " ^ (L.string_of_expr e)
    | SeqSlot es -> "Sequence\n\t" ^ (String.concat "\n\t" (List.map L.string_of_expr es))
    | ArgsSlot args -> "Arguments\n\t" ^ (String.concat "\n\t" (List.map L.string_of_arg args))
    | AttrSlot (mopt, expopt) -> let mstr = begin match mopt with
        | Some m -> string_of_memref m
        | None -> "NO MEM"
        end in
        let expstr = begin match expopt with
        | Some e -> L.string_of_expr e
        | None -> "NO EXPR"
        end in
        "Attributes " ^ mstr ^ ", " ^ expstr
    | LoopSlot (e1, e2, mopt) -> let e1str = L.string_of_expr e1 in
        let e2str = L.string_of_expr e2 in
        let mstr = begin match mopt with
        | Some m -> string_of_memref m
        | None -> "NO MEM"
        end in
        "Loop" ^
        "\n\tTest " ^ e1str ^
        "\n\tBody " ^ e2str ^
        "\n\tReturn " ^ mstr
    | BranchSlot (e1, e2) -> let e1str = L.string_of_expr e1 in
        let e2str = L.string_of_expr e2 in
        "Branch " ^ e1str ^ ", " ^ e2str

let string_of_frame: frame -> string =
    fun frame ->
    let slot_str = string_of_slot frame.slot in
    let env_mem_str = string_of_memref frame.env_mem in
    "Frame:" ^
    "\n\tSlot:\t" ^ slot_str ^
    "\n\tEnvironment:\t" ^ env_mem_str

let string_of_stack: stack -> string =
    fun s ->
    let frame_strs = List.map string_of_frame s.frame_list in
    "Stack:\n\t" ^
    (String.concat "\n\t" frame_strs) ^ "\n"

let string_of_state: state -> string =
    fun state ->
    let stack_str = string_of_stack state.stack in
    let heap_str = string_of_heap state.heap in
    let env_str = string_of_memref state.global_env_mem in
    (* let count = string_of_int state.fresh_count in *)
    "STATE:\n" ^
    stack_str ^
    heap_str ^
    "\nGlobal Environment:\t" ^ env_str

