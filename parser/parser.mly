%{
  module A = Rast
%}

%token         END_OF_INPUT
%token<string> STRING_CONST SYMBOL
%token<string> USER_OP
%token         MOD INT_DIV MATRIX_MULT OUTER_PROD KRON_PROD MATCH
%token<int>    INT_CONST
%token<float>  FLOAT_CONST COMPLEX_CONST
%token         NA NAN INFINITY
%token         FUNCTION NULL
(*
  %token         LOW
  %token         INCOMPLETE_STRING
*)
%token         LASSIGN EQ_ASSIGN RASSIGN
%token         FOR IN IF ELSE WHILE NEXT BREAK REPEAT
%token         GT GE LT LE EQ NE AND OR AND2 OR2
%token         NS_GET NS_GET_INT
(*
  %token         COMMENT LINE_DIRECTIVE
  %token         SYMBOL_FORMALS
  %token         EQ_FORMALS
  %token         EQ_SUB SYMBOL_SUB
  %token         SYMBOL_FUNCTION_CALL
  %token         SYMBOL_PACKAGE
  %token         COLON_ASSIGN
*)

%token         QUESTION DOLLAR CARAT PLUS MINUS DIV MULT TILDE COLON BANG AT
%token         LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK COMMA SEMI NEWLINE
%token         RSUPER_ASSIGN LSUPER_ASSIGN
%token         TRUE FALSE

/* This is the precedence table, low to high */
%left     QUESTION
(*
  %left     LOW
  %left     WHILE FOR REPEAT
*)
%right    IF
%left     ELSE
%right    LASSIGN LSUPER_ASSIGN
(*
  %right    EQ_ASSIGN
*)
%left     RASSIGN RSUPER_ASSIGN
%left     TILDE
%left     OR OR2
%left     AND AND2
%left     UNOT
%nonassoc GT GE LT LE EQ NE
%left     PLUS MINUS
%left     MULT DIV
%left     USER_OP MOD INT_DIV MATRIX_MULT OUTER_PROD KRON_PROD MATCH
%left     COLON
%left     UMINUS UPLUS
%right    CARAT
%left     DOLLAR AT
(*
  %left     NS_GET NS_GET_INT
  %nonassoc LBRACE
*)
%nonassoc LPAREN LBRACK
%left     NEWLINE

%start prog
%type <unit Rast.program> prog

%%

semis:
  | SEMI       {}
  | SEMI semis {}

newlines:
  | NEWLINE          {}
  | NEWLINE newlines {}

newlinesok:
  |          {}
  | newlines {}

prog:
  | END_OF_INPUT                 { [] }
  | expr_or_assign END_OF_INPUT  { [$1] }
  | newlines prog                { $2 }
  | expr_or_assign newlines prog { $1 :: $3 }
  | expr_or_assign semis prog    { $1 :: $3 }
  ;

expr_or_assign:
  | expr         { $1 }
  | equal_assign { $1 }
  ;

equal_assign:
  | expr EQ_ASSIGN          expr_or_assign { A.Bop(A.Assign, $1, $3) }
  | expr EQ_ASSIGN newlines expr_or_assign { A.Bop(A.Assign, $1, $4) }
  ;

expr:
  (* Constants *)
  | INT_CONST     { A.NumericConst (A.Int $1) }
  | FLOAT_CONST   { A.NumericConst (A.Float $1) }
  | NAN           { A.NumericConst (A.Float nan) }
  | INFINITY      { A.NumericConst (A.Float infinity) }
  | COMPLEX_CONST { A.NumericConst (A.Complex (0.0, $1)) }
  | NA            { A.NumericConst (A.Na) }
  | TRUE          { A.BoolConst true }
  | FALSE         { A.BoolConst false }
  | STRING_CONST  { A.StringConst $1 }
  | NULL          { A.Null }

  (* Identifier *)
  | SYMBOL { A.Ident { A.default_ident with name = $1 } }

  (* Operators *)
  | MINUS expr %prec UMINUS { A.Uop (A.UMinus, $2) }
  | PLUS expr %prec UPLUS   { A.Uop (A.UPlus, $2) }
  | BANG expr %prec UNOT    { A.Uop (A.Not, $2) }
  | TILDE expr              { A.Uop (A.UForm, $2) }
  | QUESTION expr           { A.Uop (A.UHelp, $2) }
  | expr COLON expr         { A.Bop (A.Range, $1, $3) }
  | expr PLUS expr          { A.Bop (A.Plus, $1, $3) }
  | expr MINUS expr         { A.Bop (A.Minus, $1, $3) }
  | expr MULT expr          { A.Bop (A.Mult, $1, $3) }
  | expr DIV expr           { A.Bop (A.Div, $1, $3) }
  | expr CARAT expr         { A.Bop (A.Exp, $1, $3) }
  | expr USER_OP expr       { A.FuncCall (A.Ident { A.default_ident with name=$2 }, A.ExprArg $1 :: [A.ExprArg $3]) }
  (*
    | expr '%' expr           { A.Bop (A.Modulus, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } (* TODO *) *)
  *)
  | expr TILDE expr         { A.Bop (A.Form, $1, $3) }
  | expr QUESTION expr      { A.Bop (A.Help, $1, $3) }
  | expr LT expr            { A.Bop (A.Lt, $1, $3) }
  | expr LE expr            { A.Bop (A.Le, $1, $3) }
  | expr EQ expr            { A.Bop (A.Eq, $1, $3) }
  | expr NE expr            { A.Bop (A.Neq, $1, $3) }
  | expr GE expr            { A.Bop (A.Ge, $1, $3) }
  | expr GT expr            { A.Bop (A.Gt, $1, $3) }
  | expr AND expr           { A.Bop (A.AndVec, $1, $3) }
  | expr OR expr            { A.Bop (A.OrVec, $1, $3) }
  | expr AND2 expr          { A.Bop (A.And, $1, $3) }
  | expr OR2 expr           { A.Bop (A.Or, $1, $3) }
  | expr MOD expr           { A.Bop (A.Mod, $1, $3) }
  | expr INT_DIV expr       { A.Bop (A.IntDiv, $1, $3) }
  | expr MATRIX_MULT expr   { A.Bop (A.MatrixMult, $1, $3) }
  | expr OUTER_PROD expr    { A.Bop (A.OuterProd, $1, $3) }
  | expr KRON_PROD expr     { A.Bop (A.KronProd, $1, $3) }
  | expr MATCH expr         { A.Bop (A.Match, $1, $3) }

  (* Assignment *)
  | expr LASSIGN expr       { A.Bop (A.Assign, $1, $3) }
  | expr RASSIGN expr       { A.Bop (A.Assign, $3, $1) }
  | expr LSUPER_ASSIGN expr { A.Bop (A.SuperAssign, $1, $3) }
  | expr RSUPER_ASSIGN expr { A.Bop (A.SuperAssign, $3, $1) }
  | LPAREN expr_or_assign RPAREN { $2 }

  (* Functions *)
  | expr LPAREN sublist RPAREN { A.FuncCall ($1, $3)}
  | FUNCTION LPAREN formlist RPAREN expr_or_assign
                               { A.FuncDec ($3, $5)}

  (* Control flow *)
  | next { $1 }
  | break { $1 }
  | whileexpr { $1 }
  | ifexpr { $1 }
  | ifelseexpr { $1 }
  | forexpr { $1 }
  (*
  | REPEAT expr_or_assign     { A.Repeat $2 }
  | WHILE cond expr_or_assign { A.While ($2, $3) }
  | IF cond expr_or_assign    { A.If ($2, $3) }
  | IF cond expr_or_assign ELSE expr_or_assign
                              { A.IfElse ($2, $3, $5) }
  | FOR LPAREN SYMBOL IN expr RPAREN expr_or_assign
                              { A.For (({A.default_ident with name=$3}, $5), $7) }
  *)

  (* Block *)
  | LBRACE exprlist RBRACE { A.Block $2 }

  (* List access *)
  | expr LBRACK LBRACK sublist RBRACK RBRACK
                               { A.ListProj ($1, $4) }
  | expr LBRACK sublist RBRACK { A.ListSub ($1, $3) }

  (* Package lookup *)
  | SYMBOL NS_GET SYMBOL                 { A.Bop (A.GetPackage, (A.Ident {A.default_ident with name=$1}), (A.Ident {A.default_ident with name=$3})) }
  | SYMBOL NS_GET STRING_CONST           { A.Bop (A.GetPackage, (A.Ident {A.default_ident with name=$1}), (A.StringConst $3)) }
  | STRING_CONST NS_GET SYMBOL           { A.Bop (A.GetPackage, (A.StringConst $1), (A.Ident {A.default_ident with name=$3})) }
  | STRING_CONST NS_GET STRING_CONST     { A.Bop (A.GetPackage, (A.StringConst $1), (A.StringConst $3)) }
  | SYMBOL NS_GET_INT SYMBOL             { A.Bop (A.GetPackageInt, (A.Ident {A.default_ident with name=$1}), (A.Ident {A.default_ident with name=$3})) }
  | SYMBOL NS_GET_INT STRING_CONST       { A.Bop (A.GetPackageInt, (A.Ident {A.default_ident with name=$1}), (A.StringConst $3)) }
  | STRING_CONST NS_GET_INT SYMBOL       { A.Bop (A.GetPackageInt, (A.StringConst $1), (A.Ident {A.default_ident with name=$3}))}
  | STRING_CONST NS_GET_INT STRING_CONST { A.Bop (A.GetPackageInt, (A.StringConst $1), (A.StringConst $3)) }

  (* Property access *)
  | expr DOLLAR SYMBOL       { A.ListProj ($1, [A.ExprArg (A.Ident {A.default_ident with name=$3})]) }
  | expr DOLLAR STRING_CONST { A.ListProj ($1, [A.ExprArg (A.StringConst $3)]) }
  | expr AT SYMBOL           { A.Bop (A.ObjAttr, $1, (A.Ident {A.default_ident with name=$3})) }
  | expr AT STRING_CONST     { A.Bop (A.ObjAttr, $1, (A.StringConst $3)) }

  ;

break:
  | BREAK { A.Break }
  | BREAK newlines { A.Break }
  ;

next:
  | NEXT { A.Next }
  | NEXT newlines { A.Next }
  ;

whileexpr:
  | WHILE cond expr_or_assign { A.While ($2, $3) }
  | WHILE newlines cond expr_or_assign { A.While ($3, $4) }
  | WHILE cond newlines expr_or_assign { A.While ($2, $4) }
  | WHILE newlines cond newlines expr_or_assign { A.While ($3, $5) }
  ;

ifexpr:
  | IF cond expr_or_assign { A.If ($2, $3) }
  | IF newlines cond expr_or_assign { A.If ($3, $4) }
  | IF cond newlines expr_or_assign { A.If ($2, $4) }
  | IF newlines cond newlines expr_or_assign { A.If ($3, $5) }
  ;

ifelseexpr:
  | IF cond expr_or_assign ELSE expr_or_assign { A.IfElse ($2, $3, $5) }
  | IF newlines cond expr_or_assign ELSE expr_or_assign { A.IfElse ($3, $4, $6) }
  | IF cond newlines expr_or_assign ELSE expr_or_assign { A.IfElse ($2, $4, $6) }
  | IF newlines cond newlines expr_or_assign ELSE expr_or_assign { A.IfElse ($3, $5, $7) }

  | IF cond expr_or_assign newlines ELSE expr_or_assign { A.IfElse ($2, $3, $6) }
  | IF newlines cond expr_or_assign newlines ELSE expr_or_assign { A.IfElse ($3, $4, $7) }
  | IF cond newlines expr_or_assign newlines ELSE expr_or_assign { A.IfElse ($2, $4, $7) }
  | IF newlines cond newlines expr_or_assign newlines ELSE expr_or_assign { A.IfElse ($3, $5, $8) }

  | IF cond expr_or_assign ELSE newlines expr_or_assign { A.IfElse ($2, $3, $6) }
  | IF newlines cond expr_or_assign ELSE newlines expr_or_assign { A.IfElse ($3, $4, $7) }
  | IF cond newlines expr_or_assign ELSE newlines expr_or_assign { A.IfElse ($2, $4, $7) }
  | IF newlines cond newlines expr_or_assign ELSE newlines expr_or_assign { A.IfElse ($3, $5, $8) }

  | IF cond expr_or_assign newlines ELSE newlines expr_or_assign { A.IfElse ($2, $3, $7) }
  | IF newlines cond expr_or_assign newlines ELSE newlines expr_or_assign { A.IfElse ($3, $4, $8) }
  | IF cond newlines expr_or_assign newlines ELSE newlines expr_or_assign { A.IfElse ($2, $4, $8) }
  | IF newlines cond newlines expr_or_assign newlines ELSE newlines expr_or_assign { A.IfElse ($3, $5, $9) }
  ;

forexpr:
  | FOR forcond expr_or_assign { A.For ($2, $3) }
  | FOR newlines forcond expr_or_assign { A.For ($3, $4) }
  | FOR forcond newlines expr_or_assign { A.For ($2, $4) }
  | FOR newlines forcond newlines expr_or_assign { A.For ($3, $5) }
  ;

cond:
  | LPAREN expr RPAREN { $2 }
  | LPAREN newlines expr RPAREN { $3 }
  | LPAREN expr newlines RPAREN { $2 }
  | LPAREN newlines expr newlines RPAREN { $3 }
  ;

forcond:
  | LPAREN SYMBOL IN expr RPAREN { ({A.default_ident with name=$2}, $4) }
  | LPAREN newlines SYMBOL IN expr RPAREN { ({A.default_ident with name=$3}, $5) }
  | LPAREN SYMBOL newlines IN expr RPAREN { ({A.default_ident with name=$2}, $5) }
  | LPAREN newlines SYMBOL newlines IN expr RPAREN { ({A.default_ident with name=$3}, $6) }

  | LPAREN SYMBOL IN newlines expr RPAREN { ({A.default_ident with name=$2}, $5) }
  | LPAREN newlines SYMBOL IN newlines expr RPAREN { ({A.default_ident with name=$3}, $6) }
  | LPAREN SYMBOL newlines IN newlines expr RPAREN { ({A.default_ident with name=$2}, $6) }
  | LPAREN newlines SYMBOL newlines IN newlines expr RPAREN { ({A.default_ident with name=$3}, $7) }

  | LPAREN SYMBOL IN expr newlines RPAREN { ({A.default_ident with name=$2}, $4) }
  | LPAREN newlines SYMBOL IN expr newlines RPAREN { ({A.default_ident with name=$3}, $5) }
  | LPAREN SYMBOL newlines IN expr newlines RPAREN { ({A.default_ident with name=$2}, $5) }
  | LPAREN newlines SYMBOL newlines IN expr newlines RPAREN { ({A.default_ident with name=$3}, $6) }

  | LPAREN SYMBOL IN newlines expr newlines RPAREN { ({A.default_ident with name=$2}, $5) }
  | LPAREN newlines SYMBOL IN newlines expr newlines RPAREN { ({A.default_ident with name=$3}, $6) }
  | LPAREN SYMBOL newlines IN newlines expr newlines RPAREN { ({A.default_ident with name=$2}, $6) }
  | LPAREN newlines SYMBOL newlines IN newlines expr newlines RPAREN { ({A.default_ident with name=$3}, $7) }
  ;

exprlist:
                                     { [] }
  | expr_or_assign                   { [$1] }
  | exprlist semis expr_or_assign    { $1 @ [$3] }
  | exprlist semis                   { $1 }
  | exprlist newlines expr_or_assign { $1 @ [$3] }
  | exprlist newlines                { $1 }
  ;

sublist :
                      { [] }
  | sub               { [$1] }
  | sublist COMMA sub { $1 @ [$3] }
  ;

sub :
    expr                        { A.ExprArg $1 }
  | SYMBOL EQ_ASSIGN            { A.IdentAssignEmpty {A.default_ident with name=$1} }
  | SYMBOL EQ_ASSIGN expr       { A.IdentAssign ({A.default_ident with name=$1}, $3) }
  | STRING_CONST EQ_ASSIGN      { A.StringAssignEmpty $1 }
  | STRING_CONST EQ_ASSIGN expr { A.StringAssign ($1, $3) }
  | NULL EQ_ASSIGN              { A.NullAssignEmpty }
  | NULL EQ_ASSIGN expr         { A.NullAssign $3 }
  ;

formlist:
                                         { [] }
  | SYMBOL                               { [A.Param {A.default_ident with name=$1}] }
  | SYMBOL EQ_ASSIGN expr                { [A.DefaultParam ({A.default_ident with name=$1}, $3)] }
  | formlist COMMA SYMBOL                { $1 @ [A.Param {A.default_ident with name=$3}] }
  | formlist COMMA SYMBOL EQ_ASSIGN expr { $1 @ [A.DefaultParam ({A.default_ident with name=$3}, $5)] }
  ;

