
(* We do the constant folding here *)

(*
  module R = Syntax
*)

open Syntax
module C = Complex

type numbinop =
    NumPlus
  | NumMinus
  | NumMult
  | NumDiv
  | NumExp
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
    
exception Numeric_Binop_Exception of numeric * numeric * string

let do_numeric_binop : numbinop -> numeric -> numeric -> numeric =
  fun op n1 n2 -> match (op, cast_numeric_pair (n1, n2)) with
    | (NumPlus, IntPair (i1, i2)) -> Int (i1 + i2)
    | (NumPlus, FloatPair (f1, f2)) -> Float (f1 +. f2)
    | (NumPlus, ComplexPair (c1, c2)) -> Complex (C.add c1 c2)

    | (NumMinus, IntPair (i1, i2)) -> Int (i1 - i2)
    | (NumMinus, FloatPair (f1, f2)) -> Float (f1 -. f2)
    | (NumMinus, ComplexPair (c1, c2)) -> Complex (C.sub c1 c2)

    | (NumMult, IntPair (i1, i2)) -> Int (i1 * i2)
    | (NumMult, FloatPair (f1, f2)) -> Float (f1 *. f2)
    | (NumMult, ComplexPair (c1, c2)) -> Complex (C.mul c1 c2)


(*
    | (NumDiv, IntPair (i1, i2)) ->
        if i2 != 0 then
          Int (i1 / i2)
        else
          raise (Numeric_Binop_Exception (n1, n2, "divide by zero"))
    | (NumDiv, FloatPair (f1, f2)) ->
        if f2 != 0.0 then
          Float (f1 /. f2)
        else
          raise (Numeric_Binop_Exception (n1, n2, "divide by zero"))
    | (NumDiv, ComplexPair ((c1r, c1i), (c2r, c2i))) ->
        if c2r != 0.0 || c2i != 0.0 then
          Complex (((c1r *. c2r) +. (c1i *. c2i)) /.
                      ((c2r *. c2r) +. (c2i *. c2i)),
                   ((c1i *. c2r) -. (c1r *. c2i)) /.
                      ((c2r *. c2r) +. (c2i *. c2i)))
        else
          raise (Numeric_Binop_Exception (n1, n2, "divide by zero"))

    (*
    | (NumMinus, IntPair (i1, i2)) -> Float (float i1 ** float i2)
    | (NumMinus, FloatPair (f1, f2)) -> Float (f1 ** f2)
    | (NumMinus, ComplexPair ((c1r, c1i), (c2r, c2i))) ->
*)

*)

