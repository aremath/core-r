
(* We do the constant folding here *)

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


