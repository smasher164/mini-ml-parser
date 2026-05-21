%token EOF

(* keywords *)
%token LET
%token REC
%token AND
%token IN
%token FUN
%token IF
%token THEN
%token ELSE
%token TRUE
%token FALSE
%token WITH
%token TYPE
%token BOOL
%token FORALL

(* punctuation / operators *)
%token ARROW       (* ->  *)
%token FATARROW    (* =>  *)
%token EQ          (* =   *)
%token COLON       (* :   *)
%token COLONCOLON  (* ::  *)
%token DOT         (* .   *)
%token COMMA       (* ,   *)
%token LPAREN      (* (   *)
%token RPAREN      (* )   *)
%token LBRACE      (* {   *)
%token RBRACE      (* }   *)
%token DOTS        (* ... *)

(* lexemes with payload *)
%token <string> IDENT
%token <string> TYVAR

%start <unit> program

%%

program:
  | EOF { () }
