module R = Rast
module L = Syntax
open Complex

let uop_to_ident: R.unop -> 'a L.ident =
    fun u -> {L.pkg = None; L.name = (R.string_of_unop u); L.ident_tag = None}

let bop_to_ident: R.binop -> 'a L.ident =
    fun b -> {L.pkg = None; L.name = (R.string_of_binop b); L.ident_tag = None}

let convert_ident: 'a R.ident -> 'a L.ident =
    fun i -> {L.pkg = i.R.pkg; L.name = i.R.name; L.ident_tag = i.R.tag}

let convert_numeric: R.numeric -> L.numeric =
    function
    | R.Int n   -> L.Int n
    | R.Float f -> L.Float f
    | R.Complex (f1, f2) -> L.Complex {re = f1; im = f2}
    | R.Na      -> L.Na

let rec convert_expr: 'a R.expr -> ('a, 'b) L.expr =
    function
    | R.NumericConst n      -> L.Const (L.Num (convert_numeric n))
    | R.StringConst s       -> L.Const (L.Str s)
    | R.BoolConst b         -> let b_num = if b then 1 else 0 in
                                L.Const (L.Num (L.Int b_num))
    | R.Null                -> L.Const (L.Num (L.Int 0)) (* TODO *)
    | R.Ident i             -> L.Ident (convert_ident i)
    | R.Uop (u, e)          -> let u_ident = uop_to_ident u in
                                let c_expr  = convert_expr e in
                                begin match u with
                                | R.UMinus -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg (L.Const (L.Num (L.Int 0)));
                                    L.Arg c_expr])
                                | R.UPlus -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg (L.Const (L.Num (L.Int 0)));
                                    L.Arg c_expr])
                                | R.Not -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                                | R.UForm -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                                | R.UHelp -> L.LambdaApp (L.Ident u_ident,
                                    [L.Arg c_expr])
                            end
    | R.Bop (op, e1, e2)    -> let b_ident = bop_to_ident op in
                                let c_e1 = convert_expr e1 in
                                let c_e2 = convert_expr e2 in
                                L.LambdaApp (L.Ident b_ident,
                                [L.Arg c_e1; L.Arg c_e2])
    | R.FuncCall (e, args)  -> let c_args = List.map convert_arg args in
                                let c_e = convert_expr e in
                                L.LambdaApp(c_e, c_args)
    | R.FuncDec (params, e) -> let c_params = List.map convert_param params in
                                let c_e = convert_expr e in
                                L.LambdaAbs (c_params, c_e)
    | R.Block []            -> convert_expr R.Null
    | R.Block es            -> begin match es with
                                | [hd]      -> convert_expr hd
                                | hd :: tl  -> L.Seq(convert_expr hd, convert_expr (R.Block tl))
                                | []        -> convert_expr R.Null (* TODO: is this really what R does? *)
                                end
    | R.ListProj (e, args)  -> failwith "ListProj not a part of Core R!"
    | R.ListSub (e, args)   -> L.ArraySub (convert_expr e, List.map convert_arg args)
    | R.If (e1, e2)         -> L.If (convert_expr e1, convert_expr e2, convert_expr R.Null) (* TODO ^ *)
    | R.IfElse (e1, e2, e3) -> L.If (convert_expr e1, convert_expr e2, convert_expr e3)
    | R.For ((i, e1), e2)   -> L.For (convert_ident i, convert_expr e1, convert_expr e2)
    | R.While (e1, e2)      -> L.While (convert_expr e1, convert_expr e2)
    | R.Repeat e            -> failwith "Repeat not a part of Core R!"
    | R.Next                -> L.Next
    | R.Break               -> L.Break

and convert_arg: 'a R.arg -> ('a, 'b) L.arg =
    function
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
    | R.Param i             -> L.Param (convert_ident i)
    | R.DefaultParam (i, e) -> L.Default (convert_ident i, convert_expr e)
    | R.ParamDots           -> L.VarParam
