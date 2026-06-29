open Sexplib0.Sexp_conv

type id = string [@@deriving sexp_of]

type ty =
  | TyBool
  | TyArrow of ty * ty
  | TyName of id
  | TyApp of ty list
[@@deriving sexp_of]

type record_ty = (id * ty) list [@@deriving sexp_of]

type row_constraint =
  | NoRow
  | OpenRow of record_ty
  | ClosedRow of record_ty
[@@deriving sexp_of]

type pred = {
  trait : id;
  args : ty list;
}
[@@deriving sexp_of]

type generic_ty = {
  type_params : (id * row_constraint) list;
  predicates : pred list;
  ty : ty;
}
[@@deriving sexp_of]

type tycon = {
  name : id;
  type_params : id list;
  ty : record_ty;
}
[@@deriving sexp_of]

type exp =
  | EBool of bool
  | EVar of id
  | ELam of id * exp
  | EApp of exp * exp
  | EIf of exp * exp * exp
  | ERecord of record_lit
  | EWith of exp * record_lit
  | EProj of exp * id
  | ELet of let_decl * exp
  | ELetRec of let_decl list * exp

and record_lit = (id * exp) list
and let_decl = id * generic_ty option * exp
[@@deriving sexp_of]

type trait_decl = {
  name : id;
  type_params : id list;
  methods : record_ty;
}
[@@deriving sexp_of]

type instance_decl = {
  trait : id;
  type_params : id list;
  args : ty list;
  context : pred list;
  methods : record_lit;
}
[@@deriving sexp_of]

type prog = tycon list * exp [@@deriving sexp_of]

(* Map over a program. Can be used by downstream consumers
   to produce an AST with only the nodes they want. *)
let map_prog
    ?(on_ty_bool    = fun ()      -> failwith "TyBool unsupported")
    ?(on_ty_arrow   = fun _ _     -> failwith "TyArrow unsupported")
    ?(on_ty_name    = fun _       -> failwith "TyName unsupported")
    ?(on_ty_app     = fun _       -> failwith "TyApp unsupported")
    ?(on_no_row     = fun ()      -> failwith "NoRow unsupported")
    ?(on_open_row   = fun _       -> failwith "OpenRow unsupported")
    ?(on_closed_row = fun _       -> failwith "ClosedRow unsupported")
    ?(on_pred       = fun _ _     -> failwith "pred unsupported")
    ?(on_generic_ty = fun _ _ _   -> failwith "generic_ty unsupported")
    ?(on_tycon      = fun _ _ _   -> failwith "tycon unsupported")
    ?(on_let_decl   = fun _ _ _   -> failwith "let_decl unsupported")
    ?(on_bool       = fun _       -> failwith "EBool unsupported")
    ?(on_var        = fun _       -> failwith "EVar unsupported")
    ?(on_lam        = fun _ _     -> failwith "ELam unsupported")
    ?(on_app        = fun _ _     -> failwith "EApp unsupported")
    ?(on_if         = fun _ _ _   -> failwith "EIf unsupported")
    ?(on_record     = fun _       -> failwith "ERecord unsupported")
    ?(on_with       = fun _ _     -> failwith "EWith unsupported")
    ?(on_proj       = fun _ _     -> failwith "EProj unsupported")
    ?(on_let        = fun _ _     -> failwith "ELet unsupported")
    ?(on_letrec     = fun _ _     -> failwith "ELetRec unsupported")
    ?(on_prog       = fun _ _     -> failwith "prog unsupported")
    (prog : prog) =
  let rec go_ty = function
    | TyBool         -> on_ty_bool ()
    | TyArrow (l, r) -> on_ty_arrow (go_ty l) (go_ty r)
    | TyName x       -> on_ty_name x
    | TyApp ts       -> on_ty_app (List.map go_ty ts)
  in
  let go_record_ty fs = List.map (fun (x, t) -> (x, go_ty t)) fs in
  let go_row = function
    | NoRow        -> on_no_row ()
    | OpenRow fs   -> on_open_row (go_record_ty fs)
    | ClosedRow fs -> on_closed_row (go_record_ty fs)
  in
  let go_pred ({ trait; args } : pred) =
    on_pred trait (List.map go_ty args)
  in
  let go_generic_ty ({ type_params; predicates; ty } : generic_ty) =
    let ps = List.map (fun (x, r) -> (x, go_row r)) type_params in
    let preds = List.map go_pred predicates in
    on_generic_ty ps preds (go_ty ty)
  in
  let go_tycon ({ name; type_params; ty } : tycon) =
    on_tycon name type_params (go_record_ty ty)
  in
  let rec go_exp = function
    | EBool b            -> on_bool b
    | EVar x             -> on_var x
    | ELam (x, e)        -> on_lam x (go_exp e)
    | EApp (f, a)        -> on_app (go_exp f) (go_exp a)
    | EIf (c, t, e)      -> on_if (go_exp c) (go_exp t) (go_exp e)
    | ERecord fs         -> on_record (go_record_lit fs)
    | EWith (e, fs)      -> on_with (go_exp e) (go_record_lit fs)
    | EProj (e, x)       -> on_proj (go_exp e) x
    | ELet (d, body)     -> on_let (go_let_decl d) (go_exp body)
    | ELetRec (ds, body) -> on_letrec (List.map go_let_decl ds) (go_exp body)
  and go_record_lit fs = List.map (fun (x, e) -> (x, go_exp e)) fs
  and go_let_decl (x, gty, rhs) =
    on_let_decl x (Option.map go_generic_ty gty) (go_exp rhs)
  in
  let (tycons, e) = prog in
  on_prog (List.map go_tycon tycons) (go_exp e)
