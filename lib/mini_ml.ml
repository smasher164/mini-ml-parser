module Ast = Ast
module Lexer = Lexer
module Parser = Parser

(** Parse a complete program from [input] and return its AST: a tuple
    of type declarations and an expression AST (see {!Ast.prog}).

    The re2ocaml-generated lexer threads its own buffer through
    [Lexer.lex], so the [Lexing.lexbuf] passed to Menhir is a dummy
    that the lexer function ignores.

    Raises [Failure] on an unexpected character and
    [Parser.Error] on a syntax error. *)
let parse_string (input : string) : Ast.prog =
  let buf = Lexer.make input in
  Parser.program (fun _ -> Lexer.lex buf) (Lexing.from_string "")
