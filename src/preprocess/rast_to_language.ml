module R = Rast
module L = Syntax
module T = Support
module N = Natives
open Complex
open Natives
open List

let ident_count = ref 32

let fresh_rident _: 'a R.ident =
    let next = !ident_count in
    let _ = incr ident_count in
    {R.pkg = None; R.name = "t$syn_" ^ string_of_int next; R.tag = None; R.src=None}

let fresh_lident _: 'a L.ident =
    let next = !ident_count in
    let _ = incr ident_count in
    {L.pkg = None; L.name = Some ("t$syn_" ^ string_of_int next); L.tag = None}

let uop_to_ident: R.unop -> 'a L.ident =
    fun u -> {L.pkg = Some N.native_rstring;
              L.name = Some (R.string_of_unop u);
              L.tag = None}

(* TODO: others? *)
let bop_to_ident : R.binop -> 'a L.ident =
  fun b ->
    match b with
    | Plus -> native_vector_add_id
    | Mult -> native_vector_mul_id
    | Div -> native_vector_div_id
    | Minus -> native_vector_sub_id
    | Mod -> native_vector_mod_id
    | Pow -> native_vector_exp_id
    (*
    | IntDiv
    | MatrixMult
    | OuterProd
    | KronProd
    | Match
    *)
    | Gt -> native_vector_gt_id
    | Ge -> native_vector_geq_id
    | Lt -> native_vector_lt_id
    | Le -> native_vector_leq_id
    | Eq -> native_vector_eq_id
    | Neq -> native_vector_neq_id
    | AndVec -> native_vector_andvec_id
    | And -> native_vector_and_id
    | OrVec -> native_vector_orvec_id
    | Or -> native_vector_or_id
    (*
    | Form
    | Help
    | ObjAttr
    *)
    | _ -> native_id_of_string (R.string_of_binop b)

let convert_ident: 'a R.ident -> 'a L.ident =
    fun i -> match i.R.pkg with
      | None -> { L.pkg = None; L.name = Some i.R.name; L.tag = i.R.tag}
      | Some s -> {L.pkg = Some i.R.pkg; L.name = Some i.R.name; L.tag = i.R.tag}

let convert_numeric: R.numeric -> L.numeric =
    function
    | R.Int n   -> L.Int (Some n)
    | R.Float f -> L.Float (Some f)
    | R.Complex (f1, f2) -> L.Complex (Some {re = f1; im = f2})
    | R.Na      -> L.Int (None) (* TODO *)

(* TODO: ObjAttr (and convert idents found on the right into strings) *)
let rec convert_expr: 'a R.expr -> ('a, 'b) L.expr =
    function
    | R.NumericConst n      -> L.Const (L.Num (convert_numeric n))
    | R.StringConst s       -> L.Const (L.Str (Some s))
    | R.BoolConst b         -> let b_num = if b then Some 1 else Some 0 in
                                L.Const (L.Bool b_num)
    | R.Null                -> L.Const (L.Num (L.Int (Some 0))) (* TODO *)
    | R.Ident i             -> L.Ident (convert_ident i)
    | R.Uop (u, e)          -> let u_ident = uop_to_ident u in
                                let c_expr  = convert_expr e in
                                begin match u with
                                | R.UMinus -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg (L.Const (L.Num (L.Int (Some 0))));
                                    L.Arg c_expr])
                                | R.UPlus -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg (L.Const (L.Num (L.Int (Some 0))));
                                    L.Arg c_expr])
                                | R.Not -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                                | R.UForm -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                                | R.UHelp -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                            end
    (* Assignment special cases *)
    (* length<- *)
    | R.Bop (R.Assign,
        R.FuncCall (R.Ident {R.name="length";_}, args),e)
                            -> assign_special_body "length" args e None
    (* [<- *)
    | R.Bop (R.Assign,
        R.ListSub (e_vec, args), e_val)
                            -> assign_special_body "[" args e_vec (Some e_val)
    (* [[<- and $<- *) (* TODO: does $ really work the same way? *)
    | R.Bop (R.Assign,
        R.ListProj (e_vec, args), e_val)
                            -> assign_special_body "[[" args e_vec (Some e_val)
    (* dimnames<- *)
    | R.Bop (R.Assign,
        R.FuncCall (R.Ident {R.name="dimnames";_}, args), e)
                            -> assign_special_body "dimnames" args e None
    (* dim<- *)
    | R.Bop (R.Assign,
        R.FuncCall (R.Ident {R.name="dims";_}, args), e)
                            -> assign_special_body "dims" args e None
    (* names<- *)
    | R.Bop (R.Assign,
        R.FuncCall (R.Ident {R.name="names";_}, args), e)
                            -> assign_special_body "names" args e None
    (* levels<- *)
    | R.Bop (R.Assign,
        R.FuncCall (R.Ident {R.name="levels";_}, args), e)
                            -> assign_special_body "levels" args e None
    | R.Bop (R.Assign, R.Ident id, rhs) ->
                                L.Assign (L.Ident (convert_ident id),
                                          convert_expr rhs)
    | R.Bop (R.Assign, R.StringConst str, rhs) ->
                                L.Assign (L.Const (L.Str (T.rstring_of_string str)),
                                          convert_expr rhs)
    | R.Bop (op, e1, e2)    -> let b_ident = bop_to_ident op in
                                let c_e1 = convert_expr e1 in
                                let c_e2 = convert_expr e2 in
                                L.LambdaApp (L.Ident b_ident,
                                [L.Arg c_e1; L.Arg c_e2])
    | R.FuncCall (Ident { name = "return" }, []) ->
                                L.Return (Const Nil)
    | R.FuncCall (Ident { name = "return" }, arg :: []) ->
                                (match convert_arg arg with
                                | Arg e -> Return e
                                | _ -> failwith "default or variadic return")
    | R.FuncCall (Ident { name = "return" }, a :: b :: _) ->
                                failwith "too many arguments passed to return"
    | R.FuncCall (Ident { name = "c" }, args) ->
                                LambdaApp (L.Ident native_vector_make_id,
                                           map convert_arg args)
    | R.FuncCall (e, args)  -> let c_args = map convert_arg args in
                                let c_e = convert_expr e in
                                L.LambdaApp(c_e, c_args)
    | R.FuncDec (params, e) -> let c_params = map convert_param params in
                                let c_e = convert_expr e in
                                L.LambdaAbs (c_params, c_e)
    | R.Block []            -> convert_expr R.Null
    | R.Block es            -> begin match es with
                                | [hd]      -> convert_expr hd
                                | hd :: tl  -> L.Seq (map convert_expr es)
                                | []        -> convert_expr R.Null (* TODO: is this really what R does? *)
                                end
    | R.ListProj (e, args)  -> LambdaApp (Ident (native_vector_subscript_id), Arg (convert_expr e) :: (map convert_arg args))
    | R.ListSub (e, args)  -> LambdaApp (Ident (native_vector_subset_id), Arg (convert_expr e) :: (map convert_arg args))
    (* | R.ListSub (e, args)   -> failwith "TODO: translate ListSub" *)
                              (* L.ArraySub (convert_expr e, map convert_arg args) *)
    | R.If (e1, e2)         -> L.If (convert_expr e1, convert_expr e2, convert_expr R.Null) (* TODO ^ *)
    | R.IfElse (e1, e2, e3) -> L.If (convert_expr e1, convert_expr e2, convert_expr e3)
    (* | R.For ((i, e1), e2)   -> L.For (convert_ident i, convert_expr e1, convert_expr e2) *)
    (* TODO: check this *)
    | R.For ((i, e1), e2)   ->
        (* tmp  holds the INDEX in the vector we're iterating over *)
        let tmp = fresh_rident () in
        let init = R.Bop (R.Assign, R.Ident tmp, R.NumericConst (R.Int 1)) in
        (* tmp2 holds the LENGTH of the vector we're iterating over *)
        let tmp2 = fresh_rident () in
        let init2 = L.Assign (L.Ident (convert_ident tmp2),
            L.LambdaApp(L.Ident native_vector_length_id, [L.Arg (convert_expr e1)])) in
        let cond = R.Bop (R.Lt, R.Ident i, e1) in
        let access = R.Bop (R.Assign, R.Ident i,
            R.ListProj(e1, [R.ExprArg (R.Ident tmp)])) in
        let incr = R.Bop (R.Assign, R.Ident tmp, R.Bop (R.Plus, R.Ident tmp, R.NumericConst (R.Int 1))) in
        let block = begin match e2 with
        | R.Block es        -> R.Block ([access; incr] @ es)
        | e                 -> R.Block [access; incr; e]
        end in
        let loop = R.While (cond, block) in
        L.Seq [convert_expr init; init2; convert_expr loop]
    | R.While (e1, e2)      -> L.While (convert_expr e1, convert_expr e2)
    | R.Repeat e            -> L.While (L.Const (L.Bool (Some 1)), convert_expr e)
    | R.Next                -> L.Next
    | R.Break               -> L.Break

and convert_arg: 'a R.arg -> ('a, 'b) L.arg =
    function
    | R.EmptyArg            -> L.Arg (L.Const L.Nil)
    | R.ExprArg (Ident { name = "..." }) -> L.VarArg
    | R.ExprArg e           -> let c_expr = convert_expr e in
                                L.Arg c_expr
    | R.IdentAssignEmpty i  -> failwith "Empty Assign not part of Core R!" (* TODO: what the heck *)
    | R.IdentAssign (i, e)  -> L.Named (convert_ident i, convert_expr e)
    | R.StringAssignEmpty s -> failwith "String Assign not part of Core R!" (* TODO: what the heck *)
    | R.StringAssign (s, e) -> failwith "String Assign not part of Core R!" (* TODO: what the heck *)
    | R.NullAssignEmpty     -> failwith "Null Assign not part of Core R!" (* TODO: what the heck *)
    | R.NullAssign e        -> failwith "Null Assign not part of Core R!" (* TODO: what the heck *)
    | R.ArgDots             -> L.VarArg

and convert_param: 'a R.param -> ('a, 'b) L.param =
    function
    | R.Param i             -> if i.R.name = "..." then
                                 L.VarParam
                               else
                                 L.Param (convert_ident i)
    | R.DefaultParam (i, e) -> L.Default (convert_ident i, convert_expr e)
    | R.ParamDots           -> L.VarParam

and assign_special_body: string -> 'a R.arg list -> 'a R.expr -> 'a R.expr option -> ('a, 'b) L.expr =
    fun s args e1 oe2 ->
    let c_args = map convert_arg args in
    let c_i = L.Ident {L.pkg=None; L.name=Some (s^"<-"); L.tag=None} in
    let c_e1 = convert_arg (R.ExprArg e1) in
    let c_args2 = match oe2 with
        | Some e2   -> let c_e2 = convert_arg (R.ExprArg e2) in
                        [c_e1] @ c_args @ [c_e2]
        | None      -> [c_e1] @ c_args in
    L.LambdaApp(c_i, c_args2)
