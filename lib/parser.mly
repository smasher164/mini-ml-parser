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
%token TRAIT
%token INSTANCE

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
  | tycons = list(tycon_decl) e = exp EOF
      { (tycons, e) }

tycon_decl:
  | TYPE name = IDENT params = list(TYVAR) EQ body = tycon_body
      { { Ast.name = name; type_params = params; ty = body } }

tycon_body:
  | LBRACE RBRACE
      { [] }
  | LBRACE fs = separated_nonempty_list(COMMA, row_field) RBRACE
      { fs }

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
  | x = IDENT COLON gty = generic_ty EQ rhs = exp
      { (x, Some gty, rhs) }

generic_ty:
  | t = ty
      { { Ast.type_params = []; predicates = []; ty = t } }
  | FORALL tvs = nonempty_list(TYVAR) DOT t = ty
      { { Ast.type_params = List.map (fun tv -> (tv, Ast.NoRow)) tvs; predicates = []; ty = t } }
  | FORALL tvs = nonempty_list(TYVAR) DOT
      cs = separated_nonempty_list(COMMA, row_constraint_decl) FATARROW t = ty
      { let params = List.map (fun tv ->
          match List.assoc_opt tv cs with
          | Some r -> (tv, r)
          | None   -> (tv, Ast.NoRow)) tvs
        in
        { Ast.type_params = params; predicates = []; ty = t } }

row_constraint_decl:
  | tv = TYVAR COLONCOLON r = row_body
      { (tv, r) }

row_body:
  | LBRACE RBRACE                       { Ast.ClosedRow [] }
  | LBRACE DOTS RBRACE                  { Ast.OpenRow [] }
  | LBRACE r = row_field_list RBRACE
      { let (fs, is_open) = r in
        if is_open then Ast.OpenRow fs else Ast.ClosedRow fs }

row_field_list:
  | f = row_field                                    { ([f], false) }
  | f = row_field COMMA DOTS                         { ([f], true) }
  | f = row_field COMMA rest = row_field_list
      { let (fs, is_open) = rest in (f :: fs, is_open) }

row_field:
  | x = IDENT COLON t = ty               { (x, t) }

ty:
  | l = app_ty ARROW r = ty   { Ast.TyArrow (l, r) }
  | t = app_ty                { t }

app_ty:
  | head = atom_ty args = list(atom_ty)
      { match args with
        | [] -> head
        | _  -> Ast.TyApp (head :: args) }

atom_ty:
  | BOOL                      { Ast.TyBool }
  | x = IDENT                 { Ast.TyName x }
  | x = TYVAR                 { Ast.TyName x }
  | LPAREN t = ty RPAREN      { t }

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
