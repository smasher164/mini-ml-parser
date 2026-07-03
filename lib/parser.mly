%{
let pred_of_ty t =
  match t with
  | Ast.TyApp (Ast.TyName n :: args) when n.[0] <> '\'' ->
      { Ast.trait = n; args }
  | Ast.TyName n when n.[0] <> '\'' ->
      { Ast.trait = n; args = [] }
  | _ ->
      failwith "expected a trait predicate before `=>`"
%}

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
%token INT
%token FLOAT
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
%token PIPE        (* |   *)

(* lexemes with payload *)
%token <string> IDENT
%token <string> TYVAR
%token <string> INT_LIT
%token <string> FLOAT_LIT

%start <Ast.prog> program

%%

program:
  | tycons = list(tycon_decl) traits = list(trait_decl)
      instances = list(instance_decl) e = exp EOF
      { { Ast.tycons; traits; instances; exp = e } }

tycon_decl:
  | TYPE name = IDENT params = list(TYVAR) EQ body = tycon_body
      { { Ast.name = name; type_params = params; ty = body } }

tycon_body:
  | LBRACE fs = separated_list(COMMA, row_field) RBRACE
      { fs }

trait_decl:
  | TRAIT name = IDENT type_params = nonempty_list(TYVAR)
      fundeps = optional_fundeps EQ methods = tycon_body
      { { Ast.name; type_params; fundeps; methods } }

optional_fundeps:
  | (* empty *)                                  { [] }
  | PIPE fds = separated_nonempty_list(COMMA, fundep)
      { fds }

fundep:
  | lhs = nonempty_list(TYVAR) ARROW rhs = nonempty_list(TYVAR)
      { { Ast.lhs; rhs } }

instance_decl:
  | INSTANCE gty = generic_ty EQ LBRACE methods = record_lit RBRACE
      { let { Ast.type_params; predicates; ty = head_ty } = gty in
        let type_params = List.map (fun (tv, rc) ->
          match rc with
          | Ast.NoRow -> tv
          | _ -> failwith (Printf.sprintf
              "instance head cannot have row constraint on %s" tv)
        ) type_params in
        { Ast.head = pred_of_ty head_ty;
          type_params;
          context = predicates;
          methods } }

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
  | FORALL tvs = nonempty_list(TYVAR) DOT body = forall_body
      { let (row_cs, preds, t) = body in
        let params = List.map (fun tv ->
          match List.assoc_opt tv row_cs with
          | Some r -> (tv, r)
          | None   -> (tv, Ast.NoRow)) tvs
        in
        { Ast.type_params = params; predicates = preds; ty = t } }

forall_body:
  | t = ty
      { ([], [], t) }
  | cs = constraint_list FATARROW t = ty
      { let (rows, preds) = cs in (rows, preds, t) }

constraint_list:
  | t = ty
      { ([], [pred_of_ty t]) }
  | rc = row_constraint_decl
      { ([rc], []) }
  | t = ty COMMA rest = constraint_list
      { let (rs, ps) = rest in (rs, pred_of_ty t :: ps) }
  | rc = row_constraint_decl COMMA rest = constraint_list
      { let (rs, ps) = rest in (rc :: rs, ps) }

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
  | INT                       { Ast.TyInt }
  | FLOAT                     { Ast.TyFloat }
  | x = IDENT                 { Ast.TyName x }
  | x = TYVAR                 { Ast.TyName x }
  | LPAREN t = ty RPAREN      { t }

app_exp:
  | f = app_exp a = atom_exp     { Ast.EApp (f, a) }
  | e = atom_exp                 { e }

atom_exp:
  | TRUE                         { Ast.EBool true }
  | FALSE                        { Ast.EBool false }
  | n = INT_LIT                  { Ast.EInt n }
  | f = FLOAT_LIT                { Ast.EFloat f }
  | x = IDENT                    { Ast.EVar x }
  | LPAREN e = exp RPAREN        { e }
  | LBRACE b = record_body RBRACE { b }
  | r = atom_exp DOT fld = IDENT { Ast.EProj (r, fld) }

record_body:
  | fs = record_lit
      { Ast.ERecord fs }
  | r = exp WITH fs = separated_nonempty_list(COMMA, record_field)
      { Ast.EWith (r, fs) }

record_lit:
  | fs = separated_list(COMMA, record_field)
      { fs }

record_field:
  | x = IDENT EQ e = exp         { (x, e) }
