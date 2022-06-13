{
  description = "marijanp's website";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-2111";
  };

  outputs = { self, flake-utils, nixpkgs, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" ] (system:
      let
        overlays = [ haskellNix.overlay (final: prev: {
          marijanp = final.haskell-nix.cabalProject {
            src = ./.;
            compiler-nix-name = "ghc8107";
            shell.tools = {
              cabal = {};
              hlint = {};
              haskell-language-server = {};
            };
          };
        })];
        pkgs = import nixpkgs { inherit system overlays; };
        flake = pkgs.marijanp.flake { };
      in flake // {
        devShells.marijanp = flake.devShell;
        defaultPackage = flake.packages."marijanp-github-io:exe:site";
      }
    );
}
