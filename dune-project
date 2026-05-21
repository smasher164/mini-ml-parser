(lang dune 3.0)

(using menhir 2.1)

(name mini_ml_parser)

(generate_opam_files true)

(package
 (name mini_ml_parser)
 (synopsis "Parser for a mini ML-like language")
 (description "Lexer (re2ocaml) and parser (Menhir) producing an AST suitable for Hindley-Milner type-checking experiments.")
 (depends
  (ocaml (>= 4.14))
  menhir
  sexplib0
  ppx_sexp_conv))
