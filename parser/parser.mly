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
%token EQ
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

%token NAMESPACE
%token ATTRIBUTE
%token LSUPASSIGN
%token RSUPASSIGN
%token ASSIGN

%token FUNCTION
%token RETURN

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

%token EOF

%%



program: {}

