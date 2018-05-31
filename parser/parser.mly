%{
module A = RAst
%}

%token LPAREN
%token RPAREN
%token LBRACKET
%token RBRACKET
%token LBRACE
%token RBRACE

%token MINUS
%token UNARY_MINUS
%token PLUS
%token UNARY_PLUS
%token BANG
%token TILDE
%token HELP
%token COLON
%token MULT
%token DIV
%token EXP
%token MODULUS
%token INTDIV
%token MATRIXMULT
%token OUTERPROD
%token KRONECKERPROD
%token MATCH
%token LT
%token GT
%token EQEQ
%token NEQ
%token GE
%token LE
%token AND
%token ANDVEC
%token OR
%token ORVEC
%token LASSIGN
%token RASSIGN
%token LISTSUBSET

%token SEMICOLON
%token COLONEQ
%token DOT3

%token COLON2
%token COLON3
%token ATTRIBUTE
%token LSUPASSIGN
%token RSUPASSIGN
%token EQASSIGN

%token FUNCTION
%token RETURN
%token IF
%token FOR
%token IN
%token WHILE
%token REPEAT
%token NEXT
%token BREAK

%token NULL
%token NA
%token INFINITY
%token NAN
%token TRUE
%token FALSE

%token<string> IDENT
%token<string> USEROP
%token<string> STRING
%token<int>    INT
%token<float>  FLOAT
%token<float>  COMPLEX

%token COMMA
%token EOF


/* Operator precedence */
%left  HELP
%left  WHILE, FOR, REPEAT
%left  LASSIGN, LSUPASSIGN
%left  EQASSIGN
%right RASSIGN, RSUPASSIGN
%left  TILDE
%left  OR, ORVEC
%left  AND, ANDVEC
%left  BANG
%left  LT, LE, GT, GE, EQEQ, NEQ
%left  PLUS, MINUS
%left  MULT, DIV
%left  USEROP, MODULUS, INTDIV, KRONECKERPROD, MATRIXMULT, OUTERPROD
%left  COLON
%left  UNARY_MINUS, UNARY_PLUS 
%left  EXP
%left  LISTSUBSET, ATTRIBUTE
%left  COLON2, COLON3
%left  LPAREN
%left  LBRACKET


%start program

%type <expr list> program

%%

ident:
    IDENT                   { { A.default_ident with name = $1 } }
  | IDENT COLON2 IDENT      { { A.default_ident
                                  with pkg = $1;
                                       name = $3 } }
  | IDENT COLON3 IDENT
                            { { A.default_ident
                                  with pkg = $1; name = $3 } }


arg:
    expr                    { A.ExprArg $1 }
  | IDENT EQASSIGN          { A.IdAssignEmpty $1 }
  | IDENT EQASSIGN expr     { A.IdAssign ($1, $3) }
  | STRING EQASSIGN         { A.StrAssignEmpty $1 }
  | STRING EQASSIGN expr    { A.StrAssign ($1, $3) }
  | NULL EQASSIGN           { A.NullAssignEmpty }
  | NULL EQASSIGN expr      { A.NullAssign $3 }


argstail:
                            { [] }
  | COMMA arg argstail      { $2 :: $3 }


args:
                            { [] }
  | arg argstail            { $1 :: $2 }


param:
    DOT3                    { A.ParamDot }
  | IDENT                   { A.Param { A.default_ident
                                          with name = $1 } }
  | IDENT EQASSIGN expr     { A.DefaultParam ( { A.default_ident
                                                   with name = $1 }
                                             , $3 ) }

paramstail:
                            { [] }
  | COMMA param paramstail  { $2 :: $3 }

params:
                            { [] }
  | param paramstail        { $1 :: $2 }
  


expr:
  /* Identifier and assignment */
    ident                 { if contains $1 ':'
                              then (String.sub $1 0 (String.index $1 ':'),
                                    String.sub $1 (String.rindex $1 ':')
                                                  (String.length $1))
                              else (None, $1) }

  /* Constants */
  | INT                   { A.ConstInt $1 }
  | FLOAT                 { A.ConstFloat $1 }
  | COMPLEX               { A.ConstComplex $1 }
  | TRUE                  { A.ConstBool true }
  | FALSE                 { A.ConstBool false }
  | NULL                  { A.Null }
  | NA                    { A.Na }

  /* Binary operators */
  | expr PLUS expr        { A.Bop (A.Plus, $1, $3) }
  | expr MINUS expr       { A.Bop (A.Minus, $1, $3) }
  | expr MULT expr        { A.Bop (A.Mult, $1, $3) }
  | expr DIV expr         { A.Bop (A.Div, $1, $3) }
  | expr EXP expr         { A.Bop (A.Exp, $1, $3) }
  | expr GT expr          { A.Bop (A.Gt, $1, $3) }
  | expr GE expr          { A.Bop (A.Ge, $1, $3) }
  | expr LT expr          { A.Bop (A.Lt, $1, $3) }
  | expr LE expr          { A.Bop (A.Le, $1, $3) }
  | expr EQEQ expr        { A.Bop (A.Eq, $1, $3) }
  | expr NEQ expr         { A.Bop (A.Neq, $1, $3) }
  | expr AND expr         { A.Bop (A.And, $1, $3) }
  | expr ANDVEC expr      { A.Bop (A.AndVec, $1, $3) }
  | expr OR expr          { A.Bop (A.Or, $1, $3) }
  | expr ORVEC expr       { A.Bop (A.OrVec, $1, $3) }

  | expr MODULUS expr     { A.Bop (A.Mod, $1, $3) }
  | expr INTDIV expr      { A.Bop (A.IntDiv, $1, $3) }
  | expr MATRIXMULT expr  { A.Bop (A.MatrixMult, $1, $3) }
  | expr OUTERPROD expr   { A.Bop (A.OuterProd, $1, $3) }
  | expr KRONECKERPROD expr
                          { A.Bop (A.KroneckerProd, $1, $3) }
  | ident EQASSIGN expr   { A.Assign ($1, $3) }
  | ident LASSIGN expr    { A.Assign ($1, $3) }
  | expr RASSIGN ident    { A.Assign ($3, $1) }
  | ident LSUPASSIGN expr { A.SuperAssign ($1, $3) }
  | expr RSUPASSIGN ident { A.SuperAssign ($3, $1) }
  | expr TILDE expr       { A.Bop (A.Form, $1, $3) }
  | expr HELP expr        { A.Bop (A.Help ($1, $3)) }
  | expr ATTRIBUTE IDENT  { A.Bop (A.ObjAttr, $1, A.Ident $3) }
  | expr COLON expr       { A.Bop (A.Range $1, $3) }



  | expr LBRACKET args RBRACKET
                          { A.Bop(A. ListSub, $1, $3) }
  | expr LBRACKET LBRACKET args RBRACKET RBRACKET
                          { A.Bop (A.ListProj, $1, $4) }
  | expr LISTSUBSET IDENT { A.Bop ( A.ListProj
                                  , $1
                                  , [ A.ExprArg (A.ConstS $3)
                                        , A.IdAssign ( { A.default_ident with
                                                           name = "exact" }
                                                     , A.ConstL false ) ]) }


  /* Unary operators */
  | BANG expr             { A.Uop (A.Plus $2) }
  | TILDE expr            { A.Uop (A.Plus $2) }
  | HELP expr             { A.Bop (A.Null, $2) }
  | MINUS expr %prec UNARY_MINUS
                          { A.Uop (A.Plus $2) }
  | PLUS expr  %prec UNARY_PLUS
                          { A.Uop (A.Plus $2) }

  | expr USEROP expr      { A.FuncCall ( A.Ident { A.default_ident with
                                                    name = $2 }
                                       , [A.ExprArg $1, A.ExprArg $3] ) }
                                       

  /* Keyworded expressions */
  | IF expr expr          { A.If ($2, $3, A.Null) }
  | IF expr expr expr     { A.If ($2, $3, $4) }
  | FOR LPAREN ident IN expr RPAREN expr
                          { A.For ($3, $5, $7) }
  | WHILE LPAREN expr RPAREN expr
                          { A.While ($3, $5) }
  | REPEAT expr           { A.Repeat $2 }
  | NEXT                  { A.Next }
  | BREAK                 { A.Break }

  /* Function call and declarations */
  | expr LPAREN args RPAREN
                          { A.FuncCall ($1, $3) }
  | FUNCTION LPAREN params RPAREN expr
                          { A.FuncDec ($3, $5) }

  /* Blocks */
  | LBRACE exprseq RBRACE { A.Block $2 }


exprseqtail:
                          { [] }
  | SEMICOLON expr exprseqtail
                          { $2 :: $3 }

exprseq:
                          { [] }
  | expr exprseqtail      { $1 :: $2 }


exprs:
                          { [] }
  | expr exprs            { $1 :: $2 }


program:
    exprs EOF             { $1 }



