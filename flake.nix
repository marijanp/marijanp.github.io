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
          apps.srht-deploy = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "srht-deploy";
              runtimeInputs = [ pkgs.gnutar pkgs.gnupg pkgs.curl ];
              text = ''
                echo "Decrypting access-token"
                TOKEN=$(gpg --decrypt ${./secrets/sourcehut-pages-access-token.gpg})
                echo "Compressing $1"
                tar -C "$1" -cvz . > site.tar.gz
                echo "Uploading ..."
                curl --oauth2-bearer "$TOKEN" \
                  -Fcontent=@site.tar.gz \
                  https://pages.sr.ht/publish/marijan.srht.site
                echo "Done"
              '';
            }}/bin/srht-deploy";
          };
          packages.default = haskellNixFlake.packages."website:exe:site";
          devShells.website = haskellNixFlake.devShell;
        };
    };
}
