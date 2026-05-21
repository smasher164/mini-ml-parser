let () =
  let input = In_channel.input_all In_channel.stdin in
  let buf = Mini_ml.Lexer.make input in
  Mini_ml.Parser.program (fun _ -> Mini_ml.Lexer.lex buf) (Lexing.from_string "")
