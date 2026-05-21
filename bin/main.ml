let () =
  let input = In_channel.input_all In_channel.stdin in
  let ast = Mini_ml.parse_string input in
  print_endline (Sexplib0.Sexp.to_string_hum (Mini_ml.Ast.sexp_of_prog ast))
