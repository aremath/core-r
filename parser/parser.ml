type token =
  | LPAREN
  | RPAREN
  | LBRACKET
  | RBRACKET
  | LBRACE
  | RBRACE
  | MINUS
  | PLUS
  | UNOT
  | TILDE
  | HELP
  | COLON
  | MULT
  | DIV
  | EXP
  | MODULUS
  | INTDIV
  | MATRIXMULT
  | OUTERPROD
  | KRONECKERPROD
  | LT
  | GT
  | EQEQ
  | NEQ
  | GE
  | LE
  | ANDVEC
  | ANDNOVEC
  | ORVEC
  | ORNOVEC
  | LASSIGN
  | RASSIGN
  | LISTSUBSET
  | SEMICOLON
  | COLONEQ
  | COLONCOLON
  | COLONCOLONCOLON
  | ATTRIBUTE
  | LSUPASSIGN
  | RSUPASSIGN
  | EQASSIGN
  | FUNCTION
  | RETURN
  | IF
  | FOR
  | WHILE
  | REPEAT
  | NEXT
  | BREAK
  | NULL
  | NA
  | INFINITY
  | NAN
  | TRUE
  | FALSE
  | IDENT of (string)
  | USEROP of (string)
  | STRING of (string)
  | INT of (int)
  | FLOAT of (float)
  | COMPLEX of (float)
  | COMMA
  | EOF

open Parsing;;
let _ = parse_error;;
# 2 "parser.mly"
module A = RAst

# 72 "parser.ml"
let yytransl_const = [|
  257 (* LPAREN *);
  258 (* RPAREN *);
  259 (* LBRACKET *);
  260 (* RBRACKET *);
  261 (* LBRACE *);
  262 (* RBRACE *);
  263 (* MINUS *);
  264 (* PLUS *);
  265 (* UNOT *);
  266 (* TILDE *);
  267 (* HELP *);
  268 (* COLON *);
  269 (* MULT *);
  270 (* DIV *);
  271 (* EXP *);
  272 (* MODULUS *);
  273 (* INTDIV *);
  274 (* MATRIXMULT *);
  275 (* OUTERPROD *);
  276 (* KRONECKERPROD *);
  277 (* LT *);
  278 (* GT *);
  279 (* EQEQ *);
  280 (* NEQ *);
  281 (* GE *);
  282 (* LE *);
  283 (* ANDVEC *);
  284 (* ANDNOVEC *);
  285 (* ORVEC *);
  286 (* ORNOVEC *);
  287 (* LASSIGN *);
  288 (* RASSIGN *);
  289 (* LISTSUBSET *);
  290 (* SEMICOLON *);
  291 (* COLONEQ *);
  292 (* COLONCOLON *);
  293 (* COLONCOLONCOLON *);
  294 (* ATTRIBUTE *);
  295 (* LSUPASSIGN *);
  296 (* RSUPASSIGN *);
  297 (* EQASSIGN *);
  298 (* FUNCTION *);
  299 (* RETURN *);
  300 (* IF *);
  301 (* FOR *);
  302 (* WHILE *);
  303 (* REPEAT *);
  304 (* NEXT *);
  305 (* BREAK *);
  306 (* NULL *);
  307 (* NA *);
  308 (* INFINITY *);
  309 (* NAN *);
  310 (* TRUE *);
  311 (* FALSE *);
  318 (* COMMA *);
    0 (* EOF *);
    0|]

let yytransl_block = [|
  312 (* IDENT *);
  313 (* USEROP *);
  314 (* STRING *);
  315 (* INT *);
  316 (* FLOAT *);
  317 (* COMPLEX *);
    0|]

let yylhs = "\255\255\
\002\000\002\000\002\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\005\000\005\000\006\000\006\000\004\000\004\000\
\004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
\004\000\004\000\004\000\004\000\004\000\004\000\004\000\007\000\
\007\000\008\000\008\000\001\000\000\000"

let yylen = "\002\000\
\001\000\003\000\003\000\001\000\002\000\003\000\002\000\003\000\
\002\000\003\000\002\000\003\000\000\000\002\000\006\000\004\000\
\001\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\002\000\
\003\000\000\000\002\000\001\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\037\000\017\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\002\000\
\003\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\018\000\019\000\000\000\000\000\
\000\000\000\000\000\000\014\000\016\000\000\000\000\000\000\000\
\000\000\000\000\015\000\012\000"

let yydgoto = "\002\000\
\004\000\005\000\030\000\031\000\052\000\032\000\000\000\000\000"

let yysindex = "\027\000\
\218\254\000\000\240\254\000\000\000\000\091\255\231\254\235\254\
\016\255\218\254\218\254\218\254\218\254\218\254\218\254\218\254\
\218\254\218\254\218\254\218\254\218\254\237\254\239\254\000\000\
\000\000\236\254\009\255\010\255\012\255\242\254\091\255\045\255\
\091\255\091\255\091\255\091\255\091\255\091\255\091\255\091\255\
\091\255\091\255\091\255\091\255\000\000\000\000\050\255\218\254\
\218\254\218\254\236\254\000\000\000\000\051\255\091\255\091\255\
\091\255\242\254\000\000\000\000"

let yyrindex = "\000\000\
\000\000\000\000\001\000\000\000\000\000\056\000\000\000\000\000\
\055\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\055\255\000\000\019\255\000\000\000\000\252\254\000\000\
\002\000\003\000\006\000\008\000\009\000\013\000\014\000\015\000\
\016\000\017\000\024\000\025\000\000\000\000\000\000\000\000\255\
\001\255\003\255\000\000\000\000\000\000\000\000\006\255\007\255\
\008\255\056\255\000\000\000\000"

let yygindex = "\000\000\
\000\000\000\000\010\000\072\000\018\000\038\000\000\000\000\000"

let yytablesize = 343
let yytable = "\004\000\
\001\000\021\000\020\000\009\000\005\000\031\000\007\000\022\000\
\023\000\010\000\006\000\008\000\024\000\027\000\025\000\029\000\
\030\000\003\000\026\000\007\000\008\000\001\000\001\000\026\000\
\028\000\001\000\001\000\001\000\001\000\027\000\024\000\001\000\
\001\000\001\000\025\000\028\000\045\000\029\000\046\000\001\000\
\001\000\001\000\001\000\001\000\001\000\007\000\008\000\051\000\
\053\000\048\000\049\000\001\000\050\000\054\000\059\000\036\000\
\001\000\004\000\013\000\011\000\058\000\009\000\005\000\047\000\
\007\000\027\000\000\000\010\000\006\000\008\000\000\000\028\000\
\006\000\029\000\000\000\060\000\000\000\000\000\000\000\000\000\
\001\000\033\000\034\000\035\000\036\000\037\000\038\000\039\000\
\040\000\041\000\042\000\043\000\044\000\009\000\000\000\000\000\
\000\000\010\000\011\000\000\000\012\000\000\000\000\000\013\000\
\014\000\015\000\000\000\000\000\000\000\000\000\000\000\016\000\
\017\000\018\000\019\000\020\000\021\000\000\000\000\000\055\000\
\056\000\057\000\000\000\022\000\000\000\000\000\000\000\000\000\
\023\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\001\000\001\000\021\000\020\000\001\000\
\001\000\031\000\001\000\022\000\023\000\001\000\001\000\001\000\
\024\000\027\000\025\000\029\000\030\000\001\000\001\000\001\000\
\001\000\001\000\001\000\026\000\028\000\000\000\000\000\000\000\
\000\000\001\000\000\000\000\000\000\000\000\000\001\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\001\000\021\000\
\020\000\000\000\000\000\031\000\000\000\022\000\023\000\000\000\
\000\000\000\000\024\000\027\000\025\000\029\000\030\000\000\000\
\000\000\000\000\000\000\000\000\000\000\026\000\028\000"

let yycheck = "\004\001\
\000\000\000\000\000\000\004\001\004\001\000\000\004\001\000\000\
\000\000\004\001\004\001\004\001\000\000\000\000\000\000\000\000\
\000\000\056\001\003\001\036\001\037\001\003\001\004\001\000\000\
\000\000\007\001\008\001\001\000\010\001\050\001\056\001\013\001\
\014\001\015\001\056\001\056\001\056\001\058\001\056\001\021\001\
\022\001\023\001\024\001\025\001\026\001\036\001\037\001\062\001\
\004\001\041\001\041\001\033\001\041\001\004\001\004\001\000\000\
\038\001\062\001\004\001\004\001\051\000\062\001\062\001\026\000\
\062\001\050\001\255\255\062\001\062\001\062\001\255\255\056\001\
\001\000\058\001\255\255\058\000\255\255\255\255\255\255\255\255\
\062\001\010\000\011\000\012\000\013\000\014\000\015\000\016\000\
\017\000\018\000\019\000\020\000\021\000\003\001\255\255\255\255\
\255\255\007\001\008\001\255\255\010\001\255\255\255\255\013\001\
\014\001\015\001\255\255\255\255\255\255\255\255\255\255\021\001\
\022\001\023\001\024\001\025\001\026\001\255\255\255\255\048\000\
\049\000\050\000\255\255\033\001\255\255\255\255\255\255\255\255\
\038\001\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\003\001\004\001\004\001\004\001\007\001\
\008\001\004\001\010\001\004\001\004\001\013\001\014\001\015\001\
\004\001\004\001\004\001\004\001\004\001\021\001\022\001\023\001\
\024\001\025\001\026\001\004\001\004\001\255\255\255\255\255\255\
\255\255\033\001\255\255\255\255\255\255\255\255\038\001\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\062\001\062\001\
\062\001\255\255\255\255\062\001\255\255\062\001\062\001\255\255\
\255\255\255\255\062\001\062\001\062\001\062\001\062\001\255\255\
\255\255\255\255\255\255\255\255\255\255\062\001\062\001"

let yynames_const = "\
  LPAREN\000\
  RPAREN\000\
  LBRACKET\000\
  RBRACKET\000\
  LBRACE\000\
  RBRACE\000\
  MINUS\000\
  PLUS\000\
  UNOT\000\
  TILDE\000\
  HELP\000\
  COLON\000\
  MULT\000\
  DIV\000\
  EXP\000\
  MODULUS\000\
  INTDIV\000\
  MATRIXMULT\000\
  OUTERPROD\000\
  KRONECKERPROD\000\
  LT\000\
  GT\000\
  EQEQ\000\
  NEQ\000\
  GE\000\
  LE\000\
  ANDVEC\000\
  ANDNOVEC\000\
  ORVEC\000\
  ORNOVEC\000\
  LASSIGN\000\
  RASSIGN\000\
  LISTSUBSET\000\
  SEMICOLON\000\
  COLONEQ\000\
  COLONCOLON\000\
  COLONCOLONCOLON\000\
  ATTRIBUTE\000\
  LSUPASSIGN\000\
  RSUPASSIGN\000\
  EQASSIGN\000\
  FUNCTION\000\
  RETURN\000\
  IF\000\
  FOR\000\
  WHILE\000\
  REPEAT\000\
  NEXT\000\
  BREAK\000\
  NULL\000\
  NA\000\
  INFINITY\000\
  NAN\000\
  TRUE\000\
  FALSE\000\
  COMMA\000\
  EOF\000\
  "

let yynames_block = "\
  IDENT\000\
  USEROP\000\
  STRING\000\
  INT\000\
  FLOAT\000\
  COMPLEX\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 86 "parser.mly"
                          ( { A.default_ident with name = _1 } )
# 359 "parser.ml"
               : 'ident))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 88 "parser.mly"
                          ( { A.default_ident with package = _1; name = _3 } )
# 367 "parser.ml"
               : 'ident))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 91 "parser.mly"
                          ( { A.default_ident with package = _1; name = _3 } )
# 375 "parser.ml"
               : 'ident))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 95 "parser.mly"
                          ( A.ArgExpr _1 )
# 382 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : string) in
    Obj.repr(
# 96 "parser.mly"
                          ( A.IdAssignEmpty _1 )
# 389 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 97 "parser.mly"
                          ( A.IdAssign (_1, _3) )
# 397 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : string) in
    Obj.repr(
# 98 "parser.mly"
                          ( A.StrAssignEmpty _1 )
# 404 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 99 "parser.mly"
                          ( A.StrAssign (_1, _3) )
# 412 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    Obj.repr(
# 100 "parser.mly"
                          ( A.NullAssignEmpty )
# 418 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 101 "parser.mly"
                          ( A.NullAssign _3 )
# 425 "parser.ml"
               : 'arg))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'arg) in
    Obj.repr(
# 105 "parser.mly"
                          ( [_2] )
# 432 "parser.ml"
               : 'arglisttail))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'arg) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'arglisttail) in
    Obj.repr(
# 106 "parser.mly"
                          ( _2 :: _3 )
# 440 "parser.ml"
               : 'arglisttail))
; (fun __caml_parser_env ->
    Obj.repr(
# 110 "parser.mly"
                          ( [] )
# 446 "parser.ml"
               : 'arglist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'arg) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'arglisttail) in
    Obj.repr(
# 111 "parser.mly"
                          ( _1 :: _2 )
# 454 "parser.ml"
               : 'arglist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 5 : 'expr) in
    let _4 = (Parsing.peek_val __caml_parser_env 2 : 'arglist) in
    Obj.repr(
# 116 "parser.mly"
                          ( A.ListProj (_1, _4) )
# 462 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 3 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : 'arglist) in
    Obj.repr(
# 118 "parser.mly"
                          ( A.ListSub (_1, _3) )
# 470 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'ident) in
    Obj.repr(
# 120 "parser.mly"
                          ( if contains _1 ':'
                              then (String.sub _1 0 (String.index _1 ':'),
                                    String.sub _1 (String.rindex _1 ':')
                                                  (String.length _1))
                              else (None, _1) )
# 481 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 125 "parser.mly"
                          ( A.ListProj
                              (_1, [ A.ArgExpr (A.ConstS _3)
                              , A.IdAssign ({ A.default_ident with
                                                name = "exact" }
                                           , A.ConstL false ) ]) )
# 493 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 130 "parser.mly"
                          ( A.ObjAttr (_1, A.Ident _3) )
# 501 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 133 "parser.mly"
                          ( A.BinOp (A.Plus, _1, _3) )
# 509 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 134 "parser.mly"
                          ( A.BinOp (A.Minus, _1, _3) )
# 517 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 135 "parser.mly"
                          ( A.BinOp (A.Mult, _1, _3) )
# 525 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 136 "parser.mly"
                          ( A.BinOp (A.Div, _1, _3) )
# 533 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 137 "parser.mly"
                          ( A.BinOp (A.Exp, _1, _3) )
# 541 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 138 "parser.mly"
                          ( A.BinOp (A.Gt, _1, _3) )
# 549 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 139 "parser.mly"
                          ( A.BinOp (A.Ge, _1, _3) )
# 557 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 140 "parser.mly"
                          ( A.BinOp (A.Lt, _1, _3) )
# 565 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 141 "parser.mly"
                          ( A.BinOp (A.Le, _1, _3) )
# 573 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 142 "parser.mly"
                          ( A.BinOp (A.Eq, _1, _3) )
# 581 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 143 "parser.mly"
                          ( A.BinOp (A.Neq, _1, _3) )
# 589 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 144 "parser.mly"
                          ( A.BinOp (A.Form, _1, _3) )
# 597 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 150 "parser.mly"
      ( [_2] )
# 604 "parser.ml"
               : 'exprseqtail))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'expr) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'exprseqtail) in
    Obj.repr(
# 152 "parser.mly"
      ( _2 :: _3 )
# 612 "parser.ml"
               : 'exprseqtail))
; (fun __caml_parser_env ->
    Obj.repr(
# 155 "parser.mly"
      ( [] )
# 618 "parser.ml"
               : 'exprseq))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'exprseqtail) in
    Obj.repr(
# 157 "parser.mly"
      ( _1 :: _2 )
# 626 "parser.ml"
               : 'exprseq))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 161 "parser.mly"
         ( _1 )
# 633 "parser.ml"
               : expr))
(* Entry program *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let program (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : expr)
