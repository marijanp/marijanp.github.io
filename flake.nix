{
  description = "marijan's website";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix/112669d1ba96fa2a1c75478d12d6f38ee2bd3ee6";
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
              website = final.haskell-nix.cabalProject {
                src = ./.;
                compiler-nix-name = "ghc924";
                shell.tools = {
                  cabal = { };
                  hlint = { };
                  haskell-language-server = { };
                };
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.website.flake { };
        in
        # remove devShell as it's not supported by flake-parts
        pkgs.lib.recursiveUpdate (builtins.removeAttrs haskellNixFlake [ "devShell" "hydraJobs" ]) {
          packages.default = haskellNixFlake.packages."website:exe:site";
          devShells.website = haskellNixFlake.devShell;
        };
    };
}
