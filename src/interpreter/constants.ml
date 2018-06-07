
(* We do the constant folding here *)

open Syntax
module C = Complex

type numbinop =
    NumPlus
  | NumMinus
  | NumMult
  | NumDiv
  | NumPow
  | NumMod
  | NumIntDiv

  | NumGt
  | NumGe
  | NumLt
  | NumLe
  | NumEq
  | NumNeq

  | NumAndVec
  | NumAnd
  | NumOrVec
  | NumOr

type castedtype =
    IntTy
  | FloatTy
  | ComplexTy
  | NaTy

type castedpair =
    IntPair of int * int
  | FloatPair of float * float
  | ComplexPair of C.t * C.t
  | NaPair

let cast_numeric_pair : numeric * numeric -> castedpair =
  fun (n1, n2) -> match (n1, n2) with
    | (Na, _) -> NaPair
    | (_, Na) -> NaPair

    | (Int i1, Int i2) -> IntPair (i1, i2)
    | (Int i, Float f) -> FloatPair (float i, f)
    | (Int i, Complex c) -> ComplexPair ({C.re=(float i); C.im=0.0}, c)

    | (Float f, Int i) -> FloatPair (f, float i)
    | (Float f1, Float f2) -> FloatPair (f1, f2)
    | (Float f, Complex c) -> ComplexPair ({C.re=f; C.im=0.0} , c)

    | (Complex c, Int i) -> ComplexPair (c, {C.re=float i; C.im=0.0})
    | (Complex c, Float f) -> ComplexPair (c, {C.re=f; C.im=0.0})
    | (Complex c1, Complex c2) -> ComplexPair (c1, c2)
    

let int_of_bool : bool -> int =
  fun b ->
    if b then 1 else 0

exception Numeric_Binop_Exception of numeric * numeric * string

let msg_div_by_zero : string =
  "divide by zero"

let msg_complex_mod : string =
  "complex modulo is not a supported operation in R"

let msg_complex_int_div : string =
  "complex integer division is not a supported operation in R"

let msg_complex_comp : string =
  "complex numbers do not form a naturally ordered set you uncultured swine"

let do_numeric_binop : numbinop -> numeric -> numeric -> numeric =
  fun op n1 n2 -> match (op, cast_numeric_pair (n1, n2)) with
    | (_, NaPair) -> Na

    | (NumPlus, IntPair (i1, i2)) -> Int (i1 + i2)
    | (NumPlus, FloatPair (f1, f2)) -> Float (f1 +. f2)
    | (NumPlus, ComplexPair (c1, c2)) -> Complex (C.add c1 c2)

    | (NumMinus, IntPair (i1, i2)) -> Int (i1 - i2)
    | (NumMinus, FloatPair (f1, f2)) -> Float (f1 -. f2)
    | (NumMinus, ComplexPair (c1, c2)) -> Complex (C.sub c1 c2)

    | (NumMult, IntPair (i1, i2)) -> Int (i1 * i2)
    | (NumMult, FloatPair (f1, f2)) -> Float (f1 *. f2)
    | (NumMult, ComplexPair (c1, c2)) -> Complex (C.mul c1 c2)

    | (NumDiv, IntPair (i1, i2)) ->
        if i2 != 0 then
          Int (i1 / i2)
        else
          raise (Numeric_Binop_Exception (n1, n2, msg_div_by_zero))
    | (NumDiv, FloatPair (f1, f2)) ->
        if f2 != 0.0 then
          Float (f1 /. f2)
        else
          raise (Numeric_Binop_Exception (n1, n2, msg_div_by_zero))
    | (NumDiv, ComplexPair (c1, c2)) ->
        if c2.C.re != 0.0 || c2.C.im != 0.0 then
          Complex (C.div c1 c2)
        else
          raise (Numeric_Binop_Exception (n1, n2, msg_div_by_zero))

    | (NumPow, IntPair (i1, i2)) -> Float (float i1 ** float i2)
    | (NumPow, FloatPair (f1, f2)) -> Float (f1 ** f2)
    | (NumPow, ComplexPair (c1, c2)) -> Complex (C.pow c1 c2)

    | (NumMod, IntPair (i1, i2)) -> Int (i1 mod i2)
    | (NumMod, FloatPair (f1, f2)) -> Float (mod_float f1 f2)
    | (NumMod, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_mod))

    | (NumIntDiv, IntPair (i1, i2)) ->
        if i2 != 0 then
          Int (i1 / i2)
        else
          raise (Numeric_Binop_Exception (n1, n2, msg_div_by_zero))
    | (NumIntDiv, FloatPair (f1, f2)) ->
        if f2 != 0.0 then
          Float (floor (f1 /. f2))
        else
          raise (Numeric_Binop_Exception (n1, n2, msg_div_by_zero))
    | (NumIntDiv, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_int_div))

    | (NumGt, IntPair (i1, i2)) -> Int (int_of_bool (i1 > i2))
    | (NumGt, FloatPair (f1, f2)) -> Int (int_of_bool (f1 > f2))
    | (NumGt, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_comp))

    | (NumGe, IntPair (i1, i2)) -> Int (int_of_bool (i1 >= i2))
    | (NumGe, FloatPair (f1, f2)) -> Int (int_of_bool (f1 >= f2))
    | (NumGe, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_comp))

    | (NumLt, IntPair (i1, i2)) -> Int (int_of_bool (i1 < i2))
    | (NumLt, FloatPair (f1, f2)) -> Int (int_of_bool (f1 < f2))
    | (NumLt, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_comp))

    | (NumLe, IntPair (i1, i2)) -> Int (int_of_bool (i1 <= i2))
    | (NumLe, FloatPair (f1, f2)) -> Int (int_of_bool (f1 <= f2))
    | (NumLe, ComplexPair _) ->
        raise (Numeric_Binop_Exception (n1, n2, msg_complex_comp))

    | (NumEq, IntPair (i1, i2)) -> Int (int_of_bool (i1 = i2))
    | (NumEq, FloatPair (f1, f2)) -> Int (int_of_bool (f1 = f2))
    | (NumEq, ComplexPair (c1, c2)) ->
        Int (int_of_bool (c1.C.re = c2.C.re && c1.C.im = c2.C.im))

    | (NumNeq, IntPair (i1, i2)) -> Int (int_of_bool (i1 != i2))
    | (NumNeq, FloatPair (f1, f2)) -> Int (int_of_bool (f1 != f2))
    | (NumNeq, ComplexPair (c1, c2)) ->
        Int (int_of_bool (c1.C.re != c2.C.re || c1.C.im != c2.C.im))

    | (NumAndVec, IntPair (i1, i2)) ->
        Int (int_of_bool (i1 != 0 && i2 != 0))
    | (NumAndVec, FloatPair (f1, f2)) ->
        Int (int_of_bool (f1 != 0.0 && f2 != 0.0))
    | (NumAndVec, ComplexPair (c1, c2)) ->
        Int (int_of_bool ((c1.C.re != 0.0 || c1.C.im != 0.0) &&
                          (c2.C.re != 0.0 || c2.C.im != 0.0)))

    | (NumAnd, IntPair (i1, i2)) ->
        Int (int_of_bool (i1 != 0 && i2 != 0))
    | (NumAnd, FloatPair (f1, f2)) ->
        Int (int_of_bool (f1 != 0.0 && f2 != 0.0))
    | (NumAnd, ComplexPair (c1, c2)) ->
        Int (int_of_bool ((c1.C.re != 0.0 || c1.C.im != 0.0) &&
                          (c2.C.re != 0.0 || c2.C.im != 0.0)))

    | (NumOrVec, IntPair (i1, i2)) ->
        Int (int_of_bool (i1 != 0 || i2 != 0))
    | (NumOrVec, FloatPair (f1, f2)) ->
        Int (int_of_bool (f1 != 0.0 || f2 != 0.0))
    | (NumOrVec, ComplexPair (c1, c2)) ->
        Int (int_of_bool ((c1.C.re != 0.0 || c1.C.im != 0.0) ||
                          (c2.C.re != 0.0 || c2.C.im != 0.0)))

    | (NumOr, IntPair (i1, i2)) ->
        Int (int_of_bool (i1 != 0 || i2 != 0))
    | (NumOr, FloatPair (f1, f2)) ->
        Int (int_of_bool (f1 != 0.0 || f2 != 0.0))
    | (NumOr, ComplexPair (c1, c2)) ->
        Int (int_of_bool ((c1.C.re != 0.0 || c1.C.im != 0.0) ||
                          (c2.C.re != 0.0 || c2.C.im != 0.0)))


