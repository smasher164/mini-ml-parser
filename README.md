# mini_ml_parser

A parser for a small ML-like language. The lexer is generated with
[re2ocaml](https://re2c.org/) and the parser with [Menhir](https://gallium.inria.fr/~fpottier/menhir/).
It produces an AST that is convenient for Hindley-Milner type-checking
and downstream experiments.

## Language

A program is a list of `type` declarations followed by a single
expression. Expressions include `let` / `let rec`, `fun`, `if`,
records with row-polymorphic update (`with`) and projection, and a
`bool` base type. See [`lib/ast.ml`](lib/ast.ml) for the full shape.

Example:

```
type pair 'a 'b = { fst : 'a, snd : 'b }

let swap = fun p -> { fst = p.snd, snd = p.fst } in
swap { fst = true, snd = false }
```

## Build

```sh
dune build
```

`lib/lexer.ml` is committed in generated form, so `re2c` is only
required if you edit `lib/lexer.re2c`. When `re2ocaml` is on `PATH`,
the dune rule in `lib/dune` regenerates and promotes the file.

A `flake.nix` is provided for a Nix dev shell with the full
toolchain (`ocaml`, `dune`, `menhir`, `re2c`, `ppx_sexp_conv`, etc.).

## Use as a library

Add `mini_ml_parser` to your `dune` `libraries` stanza, then:

```ocaml
let ast = Mini_ml.parse_string "let x = true in x"
```

`parse_string` returns an `Ast.prog`, which is a tuple of type
declarations and an expression AST. The AST derives `sexp_of` via
`ppx_sexp_conv`.

## Run the demo binary

The included executable reads a program from stdin and prints the
AST as an s-expression:

```sh
echo "true" | dune exec bin/main.exe
```
