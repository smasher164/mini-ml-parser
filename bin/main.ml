let () =
  let input = In_channel.input_all In_channel.stdin in
  let buf = Mini_ml.Lexer.make input in
  let ast = Mini_ml.Parser.program (fun _ -> Mini_ml.Lexer.lex buf) (Lexing.from_string "") in
  print_endline (Sexplib0.Sexp.to_string_hum (Mini_ml.Ast.sexp_of_prog ast))
