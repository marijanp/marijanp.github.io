{
  description = "better";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    haskellNix.url = "github:input-output-hk/haskell.nix/112669d1ba96fa2a1c75478d12d6f38ee2bd3ee6";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  };

  outputs = { self, flake-parts, nixpkgs, haskellNix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          projectName = "example";

          overlays = [
            haskellNix.overlay
            (final: prev: {
              ${projectName} = final.haskell-nix.cabalProject {
                src = ../example;
                compiler-nix-name = "ghc924";
                modules = [
                  {
                    packages = {
                      example.components.exes.example = {
                        build-tools = [ pkgs.makeWrapper ];
                        postInstall = ''
                          wrapProgram $out/bin/example --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
                        '';
                      };
                    };
                  }
                ];
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.${projectName}.flake { };
        in
        pkgs.lib.recursiveUpdate
          (builtins.removeAttrs haskellNixFlake [ "devShell" "hydraJobs" ]) # remove attributes which are not supported by flake-parts
          {
            devShells.default = haskellNixFlake.devShell;
          };
    };
}
