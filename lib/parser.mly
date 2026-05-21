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

%start <Ast.prog> program

%%

program:
  | e = exp EOF { ([], e) }

exp:
  | FUN x = IDENT ARROW body = exp
      { Ast.ELam (x, body) }
  | IF c = exp THEN t = exp ELSE e = exp
      { Ast.EIf (c, t, e) }
  | LET d = let_decl IN body = exp
      { Ast.ELet (d, body) }
  | LET REC ds = separated_nonempty_list(AND, let_decl) IN body = exp
      { Ast.ELetRec (ds, body) }
  | e = app_exp
      { e }

let_decl:
  | x = IDENT EQ rhs = exp
      { (x, None, rhs) }

app_exp:
  | f = app_exp a = atom_exp     { Ast.EApp (f, a) }
  | e = atom_exp                 { e }

atom_exp:
  | TRUE                         { Ast.EBool true }
  | FALSE                        { Ast.EBool false }
  | x = IDENT                    { Ast.EVar x }
  | LPAREN e = exp RPAREN        { e }
  | LBRACE b = record_body RBRACE { b }
  | r = atom_exp DOT fld = IDENT { Ast.EProj (r, fld) }

record_body:
  | (* empty *)
      { Ast.ERecord [] }
  | fs = separated_nonempty_list(COMMA, record_field)
      { Ast.ERecord fs }
  | r = exp WITH fs = separated_nonempty_list(COMMA, record_field)
      { Ast.EWith (r, fs) }

record_field:
  | x = IDENT EQ e = exp         { (x, e) }
