{
  description = "marijanp's website";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix/c6b80fe119af19c9c40ffadd41579ff8db675aab";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-parts, nixpkgs, haskellNix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      imports = [
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          overlays = [
            haskellNix.overlay
            (final: prev: {
              marijanp = final.haskell-nix.cabalProject {
                src = ./.;
                compiler-nix-name = "ghc923";
                shell.tools = {
                  cabal = { };
                  hlint = { };
                  haskell-language-server = { };
                };
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.marijanp.flake { };
        in
        # remove devShell as it's not supported by flake-parts
        pkgs.lib.recursiveUpdate (builtins.removeAttrs haskellNixFlake [ "devShell" ]) {
          packages.default = haskellNixFlake.packages."marijanp-github-io:exe:site";
          devShells.marijanp = haskellNixFlake.devShell;
        };
    };
}
