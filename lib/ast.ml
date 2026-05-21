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

type generic_ty = {
  type_params : (id * row_constraint) list;
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

type prog = tycon list * exp [@@deriving sexp_of]
