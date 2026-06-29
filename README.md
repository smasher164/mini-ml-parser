# mini_ml_parser

A parser for a small ML-like language. The lexer is generated with
[re2ocaml](https://re2c.org/) and the parser with [Menhir](https://gallium.inria.fr/~fpottier/menhir/).
It produces an AST that is convenient for Hindley-Milner type-checking
and downstream experiments.

## Language

A program is a list of `type`, `trait`, and `instance` declarations
followed by a single expression. Expressions include `let` / `let rec`,
`fun`, `if`, records with row-polymorphic update (`with`) and
projection, and a `bool` base type. Any type variables in an instance
head must be explicitly quantified with `forall`. See
[`lib/ast.ml`](lib/ast.ml) for the full shape.

Example:

```
type pair 'a 'b = { fst : 'a, snd : 'b }

trait Eq 'a = { eq : 'a -> 'a -> bool }
instance Eq bool = {
  eq = fun a -> fun b ->
    if a then b
    else if b then false
    else true
}
instance forall 'a. Eq 'a => Eq (pair 'a 'a) = {
  eq = fun p -> fun q ->
    if eq p.fst q.fst then eq p.snd q.snd
    else false
}

let swap = fun p -> { fst = p.snd, snd = p.fst } in
swap { fst = true, snd = false }
```

## Build

```sh
dune build
dune runtest
```

`lib/lexer.ml` is committed in generated form, so `re2c` is only
required if you edit `lib/lexer.re2c`. When `re2ocaml` is on `PATH`,
the dune rule in `lib/dune` regenerates and promotes the file.

A `flake.nix` is provided for a Nix dev shell with the full
toolchain (`ocaml`, `dune`, `menhir`, `re2c`, `ppx_sexp_conv`,
`ppx_inline_test`, etc.).

## Use as a library

Add `mini_ml_parser` to your `dune` `libraries` stanza, then:

```ocaml
let ast = Mini_ml.Parser.parse_string "let x = true in x"
```

`parse_string` returns an `Ast.prog`, which is a record of type
declarations, trait declarations, instance declarations, and an
expression AST. The AST derives `sexp_of` via `ppx_sexp_conv`. Syntax
errors raise `Mini_ml.Parser.Error`; an unexpected character raises
`Failure`.

## Transforming the AST with `map_prog`

`Ast.map_prog` is a generic fold-style mapper for downstream
consumers (e.g. a type checker) that want to convert `Ast.prog`
into their own representation. It takes one optional labeled
handler per variant across every AST node type and recurses
through the tree, so each handler receives already-converted
children.

```ocaml
open Mini_ml.Ast

let exp_only (prog : prog) : exp =
  map_prog
    ~on_bool:   (fun b -> EBool b)
    ~on_var:    (fun x -> EVar x)
    ~on_lam:    (fun x e -> ELam (x, e))
    ~on_app:    (fun f a -> EApp (f, a))
    (* ... other expression handlers ... *)
    ~on_prog:   (fun { exp; _ } -> exp)
    prog
```

Every handler defaults to `failwith "<Variant> unsupported"`, so
callers only need to supply the ones their target language cares
about. The mapper is polymorphic in the result types. Each
handler determines what the corresponding node becomes.

## Run the demo binary

The included executable reads a program from stdin and prints the
AST as an s-expression:

```sh
echo "true" | dune exec bin/main.exe
```
