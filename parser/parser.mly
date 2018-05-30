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
%token UNOT
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

%token COLONCOLON
%token COLONCOLONCOLON
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
    IDENT                 { { A.default_ident with name = $1 } }
  | IDENT COLONCOLON IDENT
                          { { A.default_ident with package = $1; name = $3 } }

  | IDENT COLONCOLONCOLON IDENT
                          { { A.default_ident with package = $1; name = $3 } }


arg:
    expr                  { A.ArgExpr $1 }
  | IDENT EQASSIGN        { A.IdAssignEmpty $1 }
  | IDENT EQASSIGN expr   { A.IdAssign ($1, $3) }
  | STRING EQASSIGN       { A.StrAssignEmpty $1 }
  | STRING EQASSIGN expr  { A.StrAssign ($1, $3) }
  | NULL EQASSIGN         { A.NullAssignEmpty }
  | NULL EQASSIGN expr    { A.NullAssign $3 }


arglisttail:
    COMMA arg             { [$2] }
  | COMMA arg arglisttail { $2 :: $3 }


arglist:
                          { [] }
  | arg arglisttail       { $1 :: $2 }


expr:
    expr LBRACKET LBRACKET arglist RBRACKET RBRACKET
                          { A.ListProj ($1, $4) }
  | expr LBRACKET arglist RBRACKET
                          { A.ListSub ($1, $3) }

  | ident                 { if contains $1 ':'
                              then (String.sub $1 0 (String.index $1 ':'),
                                    String.sub $1 (String.rindex $1 ':')
                                                  (String.length $1))
                              else (None, $1) }
  | expr LISTSUBSET IDENT { A.ListProj ($1, [ A.ArgExpr (A.ConstS $3)
                                            , A.IdAssign
                                                 ( { A.default_ident with
                                                       name = "exact" }
                                                 , A.ConstL false ) ]) }
  | expr ATTRIBUTE IDENT  { A.ObjAttr ($1, A.Ident $2) }

  /* Binary operators */
  | expr PLUS expr        { A.BinOp (A.Plus, $1, $3) }
  | expr MINUS expr       { A.BinOp (A.Minus, $1, $3) }
  | expr MULT expr        { A.BinOp (A.Mult, $1, $3) }
  | expr DIV expr         { A.BinOp (A.Div, $1, $3) }
  | expr EXP expr         { A.BinOp (A.Exp, $1, $3) }
  | expr GT expr          { A.BinOp (A.Gt, $1, $3) }
  | expr GE expr          { A.BinOp (A.Ge, $1, $3) }
  | expr LT expr          { A.BinOp (A.Lt, $1, $3) }
  | expr LE expr          { A.BinOp (A.Le, $1, $3) }
  | expr EQEQ expr        { A.BinOp (A.Eq, $1, $3) }
  | expr NEQ expr         { A.BinOp (A.Neq, $1, $3) }
  | expr TILDE expr       { A.BinOp (A.Form, $1, $3) }



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



