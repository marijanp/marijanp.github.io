{
  description = "marijanp's website";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-2111";
  };

  outputs = { self, nixpkgs, haskellNix }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
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
      };
      flake = pkgs.marijanp.flake { };
    in flake // {
      devShells.x86_64-linux.marijanp = flake.devShell;
      defaultPackage.x86_64-linux = flake.packages."marijanp-github-io:exe:site";
    };
}
