%token EOF

%start <unit> program

%%

program:
  | EOF { () }
