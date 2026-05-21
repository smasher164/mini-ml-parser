module Ast = Ast
module Lexer = Lexer
module Parser = Parser

let parse_string (input : string) : Ast.prog =
  let buf = Lexer.make input in
  Parser.program (fun _ -> Lexer.lex buf) (Lexing.from_string "")
