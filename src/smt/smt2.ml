open Smtsyntax

open List

let smt2_of_smtvar : smtvar -> string =
  fun var -> var

let smt2_of_smtconst : smtconst -> string =
  fun const -> const

let rec smt2_of_smtsort : smtsort -> string =
  fun sort ->
    match sort with
    | SortInt -> "Int"
    | SortFloat -> "Float"
    | SortDouble -> "Double"
    | SortBool -> "Bool"
    | SortVar (v, ss) ->
        "(" ^ smt2_of_smtvar v ^ " " ^
              (String.concat " " (map smt2_of_smtsort ss)) ^ ")"

let rec smt2_of_smtexpr : smtexpr -> string =
  fun smtexpr ->
    match smtexpr with
    | SmtVar v -> smt2_of_smtvar v
    | SmtConst c -> smt2_of_smtconst c

    | SmtGt (e1, e2) ->
        "(>" ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"

    | SmtGe (e1, e2) ->
        "(>= " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtLt (e1, e2) ->
        "(< " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtLe (e1, e2) ->
        "(<= " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtEq (e1, e2) ->
        "(= " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtNeq (e1, e2) ->
        "(not (= " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ "))"

    | SmtAnd (e1, e2) ->
        "(and " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtOr (e1, e2) ->
        "(or " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtNeg (e1) ->
        "(not " ^ smt2_of_smtexpr e1 ^ ")"
    | SmtImp (e1, e2) ->
        "(=> " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtIff (e1, e2) ->
        smt2_of_smtexpr (SmtAnd (SmtImp (e1, e2), SmtImp (e2, e1)))

    | SmtPlus (e1, e2) ->
        "(+ " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtSub (e1, e2) ->
        "(- " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtMult (e1, e2) ->
        "(* " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtDiv (e1, e2) ->
        "(/ " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtExp (e1, e2) -> failwith "smt2_of_expr: exponential not supported"
    | SmtMod (e1, e2) ->
        "(mod " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtRem (e1, e2) ->
        "(rem " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"

    | SmtArrGet (e1, e2) ->
        "(select " ^ smt2_of_smtexpr e1 ^ " " ^ smt2_of_smtexpr e2 ^ ")"
    | SmtArrSet (e1, e2, e3) ->
        "(store " ^ smt2_of_smtexpr e1 ^ " " ^
                    smt2_of_smtexpr e2 ^ " " ^
                    smt2_of_smtexpr e3 ^ ")"

    | SmtFunApp (f, es) ->
        "(" ^ smt2_of_smtvar f ^ " " ^
              (String.concat " " (map smt2_of_smtexpr es)) ^ ")"
    | SmtLet (bs, e) ->
      "(let (" ^
        (String.concat " "
          (map (fun (v, e) ->
          "(" ^ smt2_of_smtvar v ^ " " ^
                smt2_of_smtexpr e ^ ")") bs)) ^ ") " ^
        smt2_of_smtexpr e ^ ")"

    | SmtForAll (bs, e) ->
        "(forall (" ^
          (String.concat " "
            (map (fun (v, s) ->
              "(" ^ smt2_of_smtvar v ^ " " ^
                    smt2_of_smtsort s ^ ")") bs)) ^ ") " ^
          smt2_of_smtexpr e ^ ")"

    | SmtExists (bs, e) ->
        "(exists (" ^
          (String.concat " "
            (map (fun (v, s) ->
              "(" ^ smt2_of_smtvar v ^ " " ^
                    smt2_of_smtsort s ^ ")") bs)) ^ ") " ^
          smt2_of_smtexpr e ^ ")"
