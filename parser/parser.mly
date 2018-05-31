%{
module A = RAst
%}

%token      END_OF_INPUT (* ERROR *)
%token<string> STR_CONST SYMBOL
%token<string> USER_OP
%token<int> INT_CONST
%token<float> FLOAT_CONST COMPLEX_CONST
%token      NA_CONST
%token      FUNCTION NULL_CONST
(* %token      INCOMPLETE_STRING *)
%token      LEFT_ASSIGN EQ_ASSIGN RIGHT_ASSIGN LBB
%token      FOR IN IF ELSE WHILE NEXT BREAK REPEAT
%token      GT GE LT LE EQ NE AND OR AND2 OR2
%token      NS_GET NS_GET_INT
(*
%token      COMMENT LINE_DIRECTIVE
%token      SYMBOL_FORMALS
%token      EQ_FORMALS
%token      EQ_SUB SYMBOL_SUB
%token      SYMBOL_FUNCTION_CALL
%token      SYMBOL_PACKAGE
%token      COLON_ASSIGN
*)

%token      QUESTION DOLLAR CARAT PLUS MINUS DIV MULT TILDE COLON BANG AT
%token      LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET COMMA SEMI NEWLINE
%token      RIGHT_SUPER_ASSIGN LEFT_SUPER_ASSIGN
%token      TRUE FALSE

/* This is the precedence table, low to high */
%left       QUESTION
%left       LOW WHILE FOR REPEAT
%right      IF
%left       ELSE
%right      LEFT_ASSIGN LEFT_SUPER_ASSIGN
%right      EQ_ASSIGN
%left       RIGHT_ASSIGN RIGHT_SUPER_ASSIGN
%left       TILDE
%left       OR OR2
%left       AND AND2
%left       UNOT
%nonassoc   GT GE LT LE EQ NE
%left       PLUS MINUS
%left       MULT DIV
%left       USER_OP
%left       COLON
%left       UMINUS UPLUS
%right      CARAT
%left       DOLLAR AT
%left       NS_GET NS_GET_INT
%nonassoc   LPAREN LBRACE LBB

%start prog
%type <expr> prog

%%

prog    :   END_OF_INPUT            { A.Null }
    |   expr_or_assign NEWLINE      { $1 } (* { yyresult = xxvalue($1,3,&@1); goto yyreturn; } *)
    |   expr_or_assign SEMI         { $1 } (* { yyresult = xxvalue($1,4,&@1); goto yyreturn; } *)
    |   error                       { A.Null } (* TODO *)
    ;

expr_or_assign  :    expr                       { $1 } (* { $$ = $1; } *)
                |    equal_assign               { $1 } (* { $$ = $1; } *)
                ;

equal_assign    :    expr EQ_ASSIGN expr_or_assign              { A.Bop(A.Assign, $1, $3) } (* { $$ = xxbinary($2,$1,$3); } *)
                ;

expr    :   INT_CONST           { A.ConstNum (A.Int $1) }(* { $$ = $1;  setId( $$, @$); } *)
    |   FLOAT_CONST             { A.ConstNum (A.Float $1) }
    |   COMPLEX_CONST           { A.ConstNum (A.Complex 0 $1) }
    |   NA_CONST                { A.ConstNum (A.Na) }
    |   TRUE                    { A.ConstBool true }
    |   FALSE                   { A.ConstBool false }
    |   STR_CONST               { A.ConstString $1 } (* { $$ = $1;  setId( $$, @$); } *)
    |   NULL_CONST              { A.Null } (* { $$ = $1;  setId( $$, @$); } *)
    |   SYMBOL                  { A.Ident { A.default_ident where name = $1 } } (* { $$ = $1;  setId( $$, @$); } *)
    |   LBRACKET exprlist RBRACKET        { A.Block $2 } (* { $$ = xxexprlist($1,&@1,$2); setId( $$, @$); } *)
    |   LPAREN expr_or_assign RPAREN  { $2 } (* { $$ = xxparen($1,$2);  setId( $$, @$); } *)
    |   MINUS expr %prec UMINUS { A.Uop (A.Uminus, $2) } (* { $$ = xxunary($1,$2);  setId( $$, @$); } *)
    |   PLUS expr %prec UPLUS   { A.Uop (A.Uplus, $2) } (* $$ = xxunary($1,$2);  setId( $$, @$); } *)
    |   BANG expr %prec UNOT    { A.Uop (A.Not, $2) } (* { $$ = xxunary($1,$2);  setId( $$, @$); } *)
    |   TILDE expr              { A.Uop (A.Form $2) } (* { $$ = xxunary($1,$2);  setId( $$, @$); } *)
    |   QUESTION expr           { A.Uop (A.Help $2) } (* { $$ = xxunary($1,$2);  setId( $$, @$); } *)
    |   expr COLON  expr        { A.Bop (A.Range, $1, $3) }(* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr PLUS  expr         { A.Bop (A.Plus, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr MINUS expr         { A.Bop (A.Minus, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr MULT expr          { A.Bop (A.Mult, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr DIV expr           { A.Bop (A.Div, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr CARAT expr         { A.Bop (A.Exp, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr USER_OP expr       { A.FuncCall ($2, [$1;$3]) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    (*|   expr '%' expr         { A.Bop (A.Modulus, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *) (* TODO *) *)
    |   expr TILDE expr         { A.Bop (A.Form, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr QUESTION expr      { A.Bop (A.Help, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr LT expr            { A.Bop (A.Lt, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr LE expr            { A.Bop (A.Le, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr EQ expr            { A.Bop (A.Eq, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr NE expr            { A.Bop (A.Neq, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr GE expr            { A.Bop (A.Ge, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr GT expr            { A.Bop (A.Gt, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr AND expr           { A.Bop (A.AndVec, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr OR expr            { A.Bop (A.OrVec, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr AND2 expr          { A.Bop (A.And, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr OR2 expr           { A.Bop (A.Or, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr LEFT_ASSIGN expr   { A.Bop (A.Assign, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr RIGHT_ASSIGN expr  { A.Bop (A.Assign, $3, $1) } (* { $$ = xxbinary($2,$3,$1);  setId( $$, @$); } *)
    |   expr LEFT_SUPER_ASSIGN expr   { A.Bop (A.SuperAssign, $1, $3) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr RIGHT_SUPER_ASSIGN expr  { A.Bop (A.SuperAssign, $3, $1) } (* { $$ = xxbinary($2,$3,$1);  setId( $$, @$); } *)
    |   FUNCTION LPAREN formlist RPAREN expr_or_assign %prec LOW
                        { A.FuncDec $3, $5} (* { $$ = xxdefun($1,$3,$6,&@$);   setId( $$, @$); } *)
    |   expr LPAREN sublist RPAREN        { A.FuncCall $1, $3} (* { $$ = xxfuncall($1,$3);  setId( $$, @$); modif_token( &@1, SYMBOL_FUNCTION_CALL ) ; } *)
    |   IF cond expr_or_assign    { A.If $2, $3 } (* { $$ = xxif($1,$2,$3);  setId( $$, @$); } *)
    |   IF cond expr_or_assign ELSE expr_or_assign    { A.IfElse $2, $3, $5 }(* { $$ = xxifelse($1,$2,$3,$5);   setId( $$, @$); } *)
    |   FOR LPAREN SYMBOL IN expr RPAREN expr_or_assign %prec FOR    { A.For {A.default_ident with name=$3}, $5, $7 } (* { $$ = xxfor($1,$2,$3); setId( $$, @$); } *)
    |   WHILE cond expr_or_assign   { A.While $2, $3 } (* { $$ = xxwhile($1,$2,$3);   setId( $$, @$); } *)
    |   REPEAT expr_or_assign       { A.Repeat $2 }    (* { $$ = xxrepeat($1,$2); setId( $$, @$); } *)
    |   expr LBB sublist RBRACE RBRACE    { A.ListProj $1, $3 } (* { $$ = xxsubscript($1,$2,$3);   setId( $$, @$); } *)
    |   expr LBRACE sublist RBRACE        { A.ListSub $1, $3 } (* { $$ = xxsubscript($1,$2,$3);   setId( $$, @$); } *)
    |   SYMBOL NS_GET SYMBOL        { A.Bop (A.GetPackage, (A.Ident {A.default_ident with name=$1}), (A.Ident {A.default_ident with name=$3})) } (* { $$ = xxbinary($2,$1,$3);      setId( $$, @$); modif_token( &@1, SYMBOL_PACKAGE ) ; } *)
    |   SYMBOL NS_GET STR_CONST     { A.Bop (A.GetPackage, (A.Ident {A.default_ident with name=$1}), (A.ConstString $3)) } (* { $$ = xxbinary($2,$1,$3);      setId( $$, @$); modif_token( &@1, SYMBOL_PACKAGE ) ; } *)
    |   STR_CONST NS_GET SYMBOL     { A.Bop (A.GetPackage, (A.ConstString $1), (A.Ident {A.default_ident with name=$3})) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   STR_CONST NS_GET STR_CONST  { A.Bop (A.GetPackage, (A.ConstString $1), (A.ConstString $3)) }(* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   SYMBOL NS_GET_INT SYMBOL    { A.Bop (A.GetPackageInt, (A.Ident {A.default_ident with name=$1}), (A.Ident {A.default_ident with name=$3})) } (* { $$ = xxbinary($2,$1,$3);      setId( $$, @$); modif_token( &@1, SYMBOL_PACKAGE ) ;} *)
    |   SYMBOL NS_GET_INT STR_CONST { A.Bop (A.GetPackageInt, (A.Ident {A.default_ident with name=$1}), (A.ConstString $3)) } (* { $$ = xxbinary($2,$1,$3);      setId( $$, @$); modif_token( &@1, SYMBOL_PACKAGE ) ;} *)
    |   STR_CONST NS_GET_INT SYMBOL { A.Bop (A.GetPackageInt, (A.ConstString $1), (A.Ident {A.default_ident with name=$3}))} (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   STR_CONST NS_GET_INT STR_CONST  { A.Bop (A.GetPackageInt, (A.ConstString $1), (A.ConstString $3)) } (* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr DOLLAR SYMBOL         { A.ListProj $1, [(A.Ident {A.default_ident with name=$3})] }(* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr DOLLAR STR_CONST      { A.ListProj $1, [A.ConstString] }(* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   expr AT SYMBOL         { A.Bop (A.ObjAttr, $1, (A.Ident {A.default_ident with name=$3})) }(* { $$ = xxbinary($2,$1,$3);      setId( $$, @$); modif_token( &@3, SLOT ) ; } *)
    |   expr AT STR_CONST      { A.Bop (A.ObjAttr, $1, (A.ConstString $3)) }(* { $$ = xxbinary($2,$1,$3);  setId( $$, @$); } *)
    |   NEXT                { A.Next }(* { $$ = xxnxtbrk($1);    setId( $$, @$); } *)
    |   BREAK               { A.Break }(* { $$ = xxnxtbrk($1);    setId( $$, @$); } *)
    ;

cond    :   LPAREN expr RPAREN           { $2 } (* { $$ = xxcond($2);   } *)
    ;

(*
ifcond  :   LPAREN expr RPAREN           { $2 } (* { $$ = xxifcond($2); } *)
    ;
*)

exprlist:                            { [] } (* { $$ = xxexprlist0();   setId( $$, @$); } *)
    |   expr_or_assign               { [$1] } (* { $$ = xxexprlist1($1, &@1); } *)
    |   exprlist SEMI expr_or_assign  { $1 @ [$3] } (* { $$ = xxexprlist2($1, $3, &@3); } *)
    |   exprlist SEMI                 { $1 } (* { $$ = $1;      setId( $$, @$); } *)
    |   exprlist NEWLINE expr_or_assign { $1 @ [$3] }    (* { $$ = xxexprlist2($1, $3, &@3); } *)
    (* |   exprlist                     { $1 } (* { $$ = $1;} *) *)
    ;

sublist :                      { [] }  (* sub                { [$1] } (* { $$ = xxsublist1($1);    } *) *)
    |   sublist COMMA sub     { $1 @ [$3] } (* { $$ = xxsublist2($1,$4); } *)
    ;

sub :                               (* { $$ = xxsub0();     } *)
    expr                            { A.ExprArg $1 } (* { $$ = xxsub1($1, &@1);  } *)
    |   SYMBOL EQ_ASSIGN            { A.IdAssignEmpty {A.default_ident with name=$1} } (* { $$ = xxsymsub0($1, &@1);  modif_token( &@2, EQ_SUB ) ; modif_token( &@1, SYMBOL_SUB ) ; } *)
    |   SYMBOL EQ_ASSIGN expr       { A.IdAssign {A.default_ident with name=$1}, $3 } (* { $$ = xxsymsub1($1,$3, &@1);   modif_token( &@2, EQ_SUB ) ; modif_token( &@1, SYMBOL_SUB ) ; } *)
    |   STR_CONST EQ_ASSIGN         { A.StrAssignEmpty $1 } (* { $$ = xxsymsub0($1, &@1);  modif_token( &@2, EQ_SUB ) ; } *)
    |   STR_CONST EQ_ASSIGN expr    { A.StrAssign $1, $3 } (* { $$ = xxsymsub1($1,$3, &@1);   modif_token( &@2, EQ_SUB ) ; } *)
    |   NULL_CONST EQ_ASSIGN        { A.NullAssignEmpty } (* { $$ = xxnullsub0(&@1);     modif_token( &@2, EQ_SUB ) ; } *)
    |   NULL_CONST EQ_ASSIGN expr   { A.NullAssign $3 }  (* { $$ = xxnullsub1($3, &@1);     modif_token( &@2, EQ_SUB ) ; } *)
    ;

formlist:                       { [] } (* { $$ = xxnullformal(); } *)
    |   SYMBOL                  { [A.Param {A.default_ident with name=$1}] } (* { $$ = xxfirstformal0($1);  modif_token( &@1, SYMBOL_FORMALS ) ; } *)
    |   SYMBOL EQ_ASSIGN expr   { [A.DefaultParam {A.default_ident with name=$1}, $3] }(* { $$ = xxfirstformal1($1,$3);   modif_token( &@1, SYMBOL_FORMALS ) ; modif_token( &@2, EQ_FORMALS ) ; } *)
    |   formlist COMMA SYMBOL     { $1 @ [A.Param {A.default_ident with name=$1}] } (* { $$ = xxaddformal0($1,$3, &@3);   modif_token( &@3, SYMBOL_FORMALS ) ; } *)
    |   formlist COMMA SYMBOL EQ_ASSIGN expr  
                {$1 @ [A.DefaultParam {A.default_ident with name=$1}, $3]} (* { $$ = xxaddformal1($1,$3,$5,&@3); modif_token( &@3, SYMBOL_FORMALS ) ; modif_token( &@4, EQ_FORMALS ) ;} *)
    ;
