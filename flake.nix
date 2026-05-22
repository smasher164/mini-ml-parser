{
  description = "A parser for a mini ML-like language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.legacyPackages.${system}; {
        devShells.default = mkShell {
          buildInputs = with ocamlPackages; [
            ocaml
            dune_3
            ocaml-lsp
            odoc
            utop
            findlib
            ppx_inline_test
            ocamlformat
            sexplib
            ppx_sexp_conv
            re2c
            menhir
            menhirLib
          ];
        };

        packages.default = ocamlPackages.buildDunePackage {
          pname = "mini-ml-parser";
          version = "0.1.0";
          src = ./.;
          buildInputs = with ocamlPackages; [ sexplib ppx_sexp_conv ppx_inline_test ];
        };
      });
}
