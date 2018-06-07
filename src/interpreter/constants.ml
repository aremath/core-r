
(* We do the constant folding here *)

(*
  module R = Syntax
*)

open Syntax

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


exception Numeric_Cast_Exception of string;;

let cast_numeric_pair : numeric -> numeric -> numeric * numeric =
  fun n1 n2 -> match (n1, n2) with
    | (Na, _) -> (n1, n2)
    | (_, Na) -> (n1, n2)

    | (Int _, Int _) -> (n1, n2)
    | (Int i, Float _) -> (Float (float i), n2)
    | (Int i, Complex _) -> (Complex (float i, 0.0), n2)

    | (Float _, Int i) -> (n1, Float (float i))
    | (Float _, Float _) -> (n1, n2)
    | (Float f, Complex _) -> (Complex (f, 0.0), n2)

    | (Complex _, Int i) -> (n1, Complex (float i, 0.0))
    | (Complex _, Float f) -> (n1, Complex (f, 0.0))
    | (Complex _, Complex _) -> (n1, n2)

