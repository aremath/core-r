(* TODO: name this file something different... dereference.ml? *)
module S = Support

let resolve_vec: 'a option array -> 'a array =
    fun v ->
    Array.map (fun x -> match x with
        | Some x' -> x'
        | None    -> failwith "NA when resolving vector") v

let unresolve_vec: 'a array -> 'a option array =
    fun v ->
    Array.map (fun x -> Some x) v

let rvector_to_int_array: S.rvector -> S.rint array =
    fun vec -> match vec with
    | S.IntVec i  -> i
    | _         -> failwith "can't cast vector to int array!" (* TODO other types can be coerced *)

let rvector_to_str_array: S.rvector -> S.rstring array =
    fun vec -> match vec with
    | S.StrVec s -> s
    | _         -> failwith "can't cast vector to string array!"

let value_to_rvector: S.value -> S.rvector =
    fun value -> match value with
    | S.Vec vec   -> vec
    | _         -> failwith "can't cast! to rvector!" (* TODO: lists can be coerced *)

let value_to_int_array: S.value -> S.rint array =
    fun value -> let vec = value_to_rvector value in
    rvector_to_int_array vec

let dereference_rvector: S.memref -> S.heap -> S.rvector =
    fun mem heap ->
    match S.heap_find mem heap with
    | Some (S.DataObj (S.Vec v, _)) -> v
    | _ -> failwith "Vec expected in dereference"

(* TODO: catch a dereference error somehow? *)
let dereference: S.memref list -> S.heap -> S.heapobj list =
    fun mems heap ->
    List.map (fun mem -> S.MemRefMap.find mem heap.S.mem_map) mems

(* Get a number from a memref. Fails if the memref does not point to an int vector
 Warns if the vector has length greater than 1. *)
let get_single_rint: S.memref -> S.heap -> S.rint =
    fun mem heap ->
    let vec = dereference_rvector mem heap in
    let a = rvector_to_int_array vec in
    let _ = if (Array.length a) > 1 then Printf.printf
        "Warning: only the first element used of expression with %d elements" (Array.length a)
    else
        () in
    a.(0)

let get_single_rstr: S.memref -> S.heap -> S.rstring =
    fun mem heap ->
    let vec = dereference_rvector mem heap in
    let a = rvector_to_str_array vec in
    let _ = if (Array.length a) > 1 then Printf.printf
        "Warning: only the first element used of expression with %d elements" (Array.length a)
    else
        () in
    a.(0)

(* Type conversion *)

(* For using ex. float_of_int to convert float option to int option *)
let convert_opt: ('a -> 'b) -> 'a option -> 'b option =
    fun f ao ->
    match ao with
    | Some a -> Some (f a)
    | None -> None

(* Newer versions of ocaml have these in standard library *)
let float_of_string_opt: string -> float option =
    fun s ->
    try Some (float_of_string s)
    with Failure "float_of_string" -> None

let int_of_string_opt: string -> int option =
    fun s ->
    try Some (int_of_string s)
    with Failure "int_of_string" -> None

(* TODO: ocaml's string conversion might be different from R's *)
let float_opt_of_string_opt: string option -> float option =
    fun so ->
    match so with
    | Some s -> float_of_string_opt s
    | None -> None

let int_opt_of_string_opt: string option -> int option =
    fun so ->
    match so with
    | Some s -> int_of_string_opt s
    | None -> None

(* TODO: other conversion nuances cf. type_convert.ml *)

(* TODO: warn when discarding imaginary parts of complex *)
let rvector_as_integer: S.rvector -> S.rvector =
    function
    | S.IntVec i -> S.IntVec (Array.copy i) (* TODO: is this copy necessary? *)
    | S.FloatVec f -> S.IntVec (Array.map (convert_opt int_of_float) f)
    | S.ComplexVec c -> S.IntVec (Array.map (convert_opt (fun cplx -> int_of_float cplx.Complex.re)) c)
    | S.StrVec s -> S.IntVec (Array.map int_opt_of_string_opt s)
    | S.BoolVec b -> S.IntVec (Array.copy b) (* TODO: is this copy necessary? *)

(* R calls its float vector conversion as.double *)
let rvector_as_double: S.rvector -> S.rvector =
    function
    | S.IntVec i -> S.FloatVec (Array.map (convert_opt float_of_int) i)
    | S.FloatVec f -> S.FloatVec (Array.copy f)
    | S.ComplexVec c -> S.FloatVec (Array.map (convert_opt (fun cplx -> cplx.Complex.re)) c)
    | S.StrVec s -> S.FloatVec (Array.map float_opt_of_string_opt s)
    | S.BoolVec b -> S.FloatVec (Array.map (convert_opt float_of_int) b)

let cplx_of_int: S.rint -> S.rcomplex =
    convert_opt (fun i ->
        {Complex.re = (float_of_int i); Complex.im = 0.0})

let cplx_of_float: S.rfloat -> S.rcomplex =
    convert_opt (fun f ->
        {Complex.re = f; Complex.im = 0.0})

let rvector_as_complex: S.rvector -> S.rvector =
    function
    | S.IntVec i -> S.ComplexVec (Array.map cplx_of_int i)
    | S.FloatVec f -> S.ComplexVec (Array.map cplx_of_float f)
    | S.ComplexVec c -> S.ComplexVec (Array.copy c)
    | S.StrVec s -> failwith "No string to complex conversion" (* TODO *)
    | S.BoolVec b -> S.ComplexVec (Array.map cplx_of_int b)

let string_of_logical: S.rbool -> S.rstring =
    function
    | Some 0 -> Some "FALSE"
    | Some 1 -> Some "TRUE"
    | Some _ -> failwith "Invalid logical in string conversion"
    | None -> None

let rvector_as_character: S.rvector -> S.rvector =
    function
    | S.IntVec i -> S.StrVec (Array.map (convert_opt string_of_int) i)
    | S.FloatVec f -> S.StrVec (Array.map (convert_opt string_of_float) f)
    | S.ComplexVec c -> failwith "No complex to string conversion" (* TODO *)
    | S.StrVec s -> S.StrVec (Array.copy s)
    | S.BoolVec b -> S.StrVec (Array.map string_of_logical b)

let logical_of_int: S.rint -> S.rbool =
    function
    | Some 0 -> Some 0
    | None -> None
    | _ -> Some 1

let logical_of_string: S.rstring -> S.rbool =
    function
    | Some "T" -> Some 1
    | Some "TRUE" -> Some 1
    | Some "True" -> Some 1
    | Some "true" -> Some 1
    | Some "F" -> Some 0
    | Some "FALSE" -> Some 0
    | Some "False" -> Some 0
    | Some "false" -> Some 0
    | Some _ -> None
    | None -> None

let logical_of_float: S.rfloat -> S.rbool =
    function
    | Some f ->
        (* If f is NaN then NA_BOOL *)
        if f <> f then None else
        (* If f is 0 then false *)
        if f = 0.0 then Some 0 else
        Some 1
    | None -> None

let logical_of_complex: S.rcomplex -> S.rbool =
    function
    | Some c ->
        (* Check for either part being NaN *)
        if (c.Complex.re <> c.Complex.re) || (c.Complex.im <> c.Complex.im) then None else
        (* Nonzero real OR complex part means true *)
        if (c.Complex.re = 0.0) && (c.Complex.im = 0.0) then Some 0 else
        Some 1
    | None -> None

let rvector_as_logical: S.rvector -> S.rvector =
    function
    | S.IntVec i -> S.BoolVec (Array.map logical_of_int i)
    | S.FloatVec f -> S.BoolVec (Array.map logical_of_float f)
    | S.ComplexVec c -> S.BoolVec (Array.map logical_of_complex c)
    | S.StrVec s -> S.BoolVec (Array.map logical_of_string s)
    | S.BoolVec b -> S.BoolVec (Array.copy b)


