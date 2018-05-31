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
%token PLUS
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
%token ANDVEC
%token ANDNOVEC
%token ORVEC
%token ORNOVEC
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



%start program

%type <expr> program

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
    expr                    { A.ArgExpr $1 }
  | IDENT EQASSIGN          { A.IdAssignEmpty $1 }
  | IDENT EQASSIGN expr     { A.IdAssign ($1, $3) }
  | STRING EQASSIGN         { A.StrAssignEmpty $1 }
  | STRING EQASSIGN expr    { A.StrAssign ($1, $3) }
  | NULL EQASSIGN           { A.NullAssignEmpty }
  | NULL EQASSIGN expr      { A.NullAssign $3 }


argstail:
    COMMA arg               { [$2] }
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
    COMMA param             { [$2] }
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
  | expr LSUPASSIGN ident { A.SuperAssign ($3, $1) }
  | expr TILDE expr       { A.Bop (A.Form, $1, $3) }
  | expr HELP expr        { A.Bop (A.Help ($1, $3)) }
  | expr ATTRIBUTE IDENT  { A.Bop (A.ObjAttr, $1, A.Ident $3) }



  | expr LBRACKET args RBRACKET
                          { A.Bop(A. ListSub, $1, $3) }
  | expr LBRACKET LBRACKET args RBRACKET RBRACKET
                          { A.Bop (A.ListProj, $1, $4) }
  | expr LISTSUBSET IDENT { A.Bop ( A.ListProj
                                  , $1
                                  , [ A.ArgExpr (A.ConstS $3)
                                        , A.IdAssign ( { A.default_ident with
                                                      name = "exact" }
                                                , A.ConstL false ) ]) }


  /* Unary operators */
  | MINUS expr            { A.Uop (A.Plus $2) }
  | PLUS expr             { A.Uop (A.Plus $2) }
  | BANG expr             { A.Uop (A.Plus $2) }
  | TILDE expr            { A.Uop (A.Plus $2) }

  /* Keyworded expressions */
  | IF expr expr          { A.If ($2, $3, A.Null) }
  | IF expr expr expr     { A.If ($2, $3, $4) }
  | FOR ident expr expr   { A.For ($2, $3, $4) }
  | WHILE expr expr       { A.While ($2, $3) }
  | REPEAT expr           { A.Repeat $2 }
  | NEXT                  { A.Next }
  | BREAK                 { A.Break }

  /* Function call and declarations */
  | expr LPAREN args RPAREN
                          { A.FuncCall ($1, $3) }
  | expr LPAREN params RPAREN
                          { A.FuncDec ($1, $3) }


exprseqtail:
    SEMICOLON expr
      { [$2] }
  | SEMICOLON expr exprseqtail
      { $2 :: $3 }

exprseq:
      { [] }
  | expr exprseqtail
      { $1 :: $2 }


program:
    expr { $1 }



