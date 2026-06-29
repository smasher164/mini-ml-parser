module Ast = Ast
open Ast

module Parser = struct
  exception Error = Parser.Error

  (** Parse a complete program from [input] and return its AST: a tuple
      of type declarations and an expression AST (see {!Ast.prog}).

      The re2ocaml-generated lexer threads its own buffer through
      [Lexer.lex], so the [Lexing.lexbuf] passed to Menhir is a dummy
      that the lexer function ignores.

      Raises [Failure] on an unexpected character and
      [Error] on a syntax error. *)
  let parse_string (input : string) : prog =
    let buf = Lexer.make input in
    Parser.program (fun _ -> Lexer.lex buf) (Lexing.from_string "")
end

let%test "map_prog identity round-trip" =
  let source = {|
type empty = { }
type pair 'a 'b = { fst: 'a, snd: 'b }

let mk : forall 'a 'b. 'a -> 'b -> pair 'a 'b =
  fun x -> fun y -> { fst = x, snd = y }
in
let project : forall 'r. 'r :: { x : bool, ... } => 'r -> bool =
  fun r -> r.x
in
let strict : forall 'r. 'r :: { x : bool } => 'r -> bool =
  fun r -> r.x
in
let rec id = fun x -> x
and other = fun y -> y
in
let p = mk true false in
let q = { p with fst = false } in
if project q then id true else strict (other q)
|}
  in
  let roundtrip (prog : prog) : prog =
    map_prog
      ~on_ty_bool:   (fun () -> TyBool)
      ~on_ty_arrow:  (fun l r -> TyArrow (l, r))
      ~on_ty_name:   (fun x -> TyName x)
      ~on_ty_app:    (fun ts -> TyApp ts)
      ~on_no_row:    (fun () -> NoRow)
      ~on_open_row:  (fun fs -> OpenRow fs)
      ~on_closed_row:(fun fs -> ClosedRow fs)
      ~on_pred:      (fun trait args -> { trait; args })
      ~on_generic_ty:(fun parts -> parts)
      ~on_tycon:     (fun name type_params ty -> { name; type_params; ty })
      ~on_trait_decl:(fun name type_params methods -> { name; type_params; methods })
      ~on_instance_decl:(fun trait type_params args context methods ->
        { trait; type_params; args; context; methods })
      ~on_let_decl:  (fun x gty rhs -> (x, gty, rhs))
      ~on_bool:      (fun b -> EBool b)
      ~on_var:       (fun x -> EVar x)
      ~on_lam:       (fun x e -> ELam (x, e))
      ~on_app:       (fun f a -> EApp (f, a))
      ~on_if:        (fun c t e -> EIf (c, t, e))
      ~on_record:    (fun fs -> ERecord fs)
      ~on_with:      (fun e fs -> EWith (e, fs))
      ~on_proj:      (fun e x -> EProj (e, x))
      ~on_let:       (fun d body -> ELet (d, body))
      ~on_letrec:    (fun ds body -> ELetRec (ds, body))
      ~on_prog:      (fun parts -> parts)
      prog
  in
  let original = Parser.parse_string source in
  let copy = roundtrip original in
  Sexplib0.Sexp.to_string (sexp_of_prog original)
  = Sexplib0.Sexp.to_string (sexp_of_prog copy)
