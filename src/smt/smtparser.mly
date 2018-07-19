%{

%}

%token         END_OF_INPUT
%token<int>    INT_CONST
%token<float>  FLOAT_CONST
%token<string> STRING_CONST
%token<string> SYMBOL

%token LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK
%token AS FORALL EXISTS LET BANG

%token SET_LOGIC
%token DECLARE_FUN DEFINE_FUN DECLARE_SORT DEFINE_SORT
%token ASSERT CHECK_SAT PUSH POP EXIT

%%

prog:
    END_OF_INPUT { [] }
  | NEWLINE prog { $2 }
  | stmt prog    { $1 :: $2 }
  ;

cmd:
  | END_OF_INPUT { [] }

