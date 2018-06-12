module S = Syntax

(* TODO: better error messaging *)

int_of_bool = function
    | true  -> 1
    | false -> 0

let int_to_bool: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Int None))      -> S.Const (S.Bool None)
    | S.Const (S.Num (S.Int (Some x)))  -> let b = S.Bool (x<>0) in
        S.Const(b)
    | _ -> failwith "Integer expected"

let float_to_bool: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Float None))        -> S.Const (S.Bool None)
    | S.Const (S.Num (S.Float (Some x)))    -> let b = if x<>x then S.Bool None (* x<>x means x is NaN *)
        else S.Bool (x<>0) in S.Const(b)
    | _ -> failwith "Float expected"

let complex_to_bool: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Complex None))      -> S.Const (S.Bool None)
    | S.Const (S.Num (S.Complex (Some x))   -> let b = if (x.re <> x.re) || (x.im <> x.im) then S.Bool None
        else S.Bool (x.re <> 0) || (x.im <> 0) in S.Const(b)
    | _ -> failwith "Complex expected"

let str_to_bool_help: string -> bool option =
    function
    | "T"       -> Some true
    | "TRUE"    -> Some true
    | "True"    -> Some true
    | "true"    -> Some true
    | "F"       -> Some false
    | "FALSE"   -> Some false
    | "False"   -> Some false
    | "false"   -> Some false
    | _         -> None

let string_to_bool: S.expr -> S.expr =
    function
    | S.Const (S.String None)       -> S.Const (S.Bool None)
    | S.Const (S.String (Some s))   -> S.Const (S.Bool (str_to_bool_help s))
    | 
    | _ -> failwith "String expected"

let bool_to_int: S.expr -> S.expr =
    function
    | S.Const (S.Bool None)         -> S.Const (S.Num (S.Int None))
    | S.Const (S.Bool (Some b))     -> S.Const (S.Num (S.Int (Some b)))
    | _ -> failwith "Bool expected"

let float_to_int_help: float option -> int option = function
    | Some x when x > max_int || x < min_int -> let _ = Printf.printf 
        "Float conversion exceeds integer bounds" in None
    | Some x -> Some (int_of_float x)
    | None -> None

(* TODO: is there a separate float NA? *)
let float_to_int: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Float x) )      -> S.Const (S.Num (S.Int (float_to_int_help x)))
    | _ -> failwith "Float expected"

let complex_to_int_help: Complex.complex option -> int option = function
    | Some x when x.re > max_int    -> None
    | Some x when x.im > max_int    -> None
    | Some x when x.im <> 0         -> let _ = Printf.printf "Implicit conversion of complex" in
        Some (int_of_float x.re)
    | Some x                        -> Some (int_of_float x.re)
    | None     -> None

let complex_to_int: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Complex x)      -> S.Const (S.Num (S.Int (complex_to_int_help x)))
    | _ -> failwith "Complex expected"

(* TODO: R's conversion may be slightly different *)
let string_to_int: S.expr -> S.expr =
    function
    | S.Const (S.String None)   -> S.Const (S.Num (S.Int None))
    | S.Const (S.String s)      -> S.Const (S.Num (S.Int (Some (int_of_string s))))
    | _ -> failwith "String expected"

let bool_to_float: S.expr -> S.expr =
    function
    | S.Const (S.Bool None)     -> S.Const (S.Num (S.Float None))
    | S.Const (S.Bool (Some b)) -> S.Const (S.Num (S.Float (Some (float_of_int b))))
    | _ -> failwith "Bool expected"

let int_to_float: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Int None))      -> S.Const (S.Num (S.Float None))
    | S.Const (S.Num (S.Int (Some x)))  -> S.Const (S.Num (S.Float (float_of_int x)))
    | _ -> failwith "Int expected"

let complex_to_float_help: Complex.complex option -> float option = function
    | Some x -> begin match x.im with
        | 0.0 -> let _ = Printf.printf("Implicit conversion of complex") in Some(x.re)
                end
    | None  -> None

let complex_to_float: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Complex x)) -> S.Const (S.Num (S.Float (complex_to_float_help x)))
    | _ -> failwith "Complex expected"

let string_to_float: S.expr -> S.expr =
    function
    | S.Const (S.String None)       -> S.Const (S.Num (S.Float None))
    | S.Const (S.String (Some s))   -> S.Const (S.Num (S.Float (Some (float_of_string s))))
    | _ -> failwith "String expected"

let bool_to_complex: S.expr -> S.expr =
    function
    | S.Const (S.Bool None)     -> S.Const (S.Num (S.Complex None))
    | S.Const (S.Bool (Some b)) -> S.Const (S.Num (S.Complex (Some ({re=(float_of_int b), im=0}))))
    | _ -> failwith "Bool expected"

(* TODO: what if x is NaN? *)
let float_to_complex: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Float None))        -> S.Const (S.Num (S.Complex None)) (* TODO: R has a complex number made from two NA_REALs *)
    | S.Const (S.Num (S.Float (Some x)))    -> S.Const (S.Num (S.Complex (Some {re=x, im=0})))
    | _ -> failwith "Float expected"

(* TODO: see /src/coerce.c for R's implementation *)
let string_to_complex: S.expr -> S.expr =
    function
    | _ -> failwith "String to Complex unimplemented!"

let bool_to_string: S.expr -> S.expr =
    function
    | S.Const (S.Bool None)     -> S.Const (S.String None)
    | S.Const (S.Bool (Some x)) -> S.Const (S.String (if x = 1 then "True" else "False"))
    | _ -> failwith "Bool expected"

let int_to_string: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Int None))      -> S.Const (S.String None)
    | S.Const (S.Num (S.Int (Some x)))  -> S.Const (S.String (Some (string_of_int x)))
    | _ -> failwith "Int expected"

(* TODO: this formatting is probably subtly wrong *)
let complex_to_string: S.expr -> S.expr =
    function
    | S.Const (S.Num (S.Complex None))      -> S.Const (S.String None)
    | S.Const (S.Num (S.Complex (Some x)))  -> let s = Printf.sprintf "%f + %fi" x.re x.im in
        S.Const (S.String (Some s))
    | _ -> failwith "Complex expected"
