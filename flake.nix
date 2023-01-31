{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    horizon-platform.url = "git+https://gitlab.homotopic.tech/horizon/horizon-platform?rev=046c7305362aa0b3445539f9d78e648dd65167b7";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          haskellPackages =
            with pkgs.haskell.lib.compose; inputs'.horizon-platform.legacyPackages.extend
              (_: _: {
                website = self.callCabal2nix "website" ./. { };
              });
        in
        {
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
            programs.cabal-fmt.enable = true;
            settings.formatter = {
              "fourmolu" = {
                command = pkgs.haskellPackages.fourmolu;
                options = [
                  "--ghc-opt"
                  "-XImportQualifiedPost"
                  "--ghc-opt"
                  "-XTypeApplications"
                  "--mode"
                  "inplace"
                  "--check-idempotence"
                ];
                includes = [ "*.hs" ];
              };
            };
          };

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
                  https://pages.sr.ht/publish/marijan.pro
                rm site.tar.gz
                echo "Done"
              '';
            }}/bin/srht-deploy";
          };
          packages.default = haskellPackages.website;
          devShells.default = haskellPackages.shellFor {
            packages = p: [ p.website ];
            withHoogle = false;
            nativeBuildInputs = [ ];
          };
        };
    };
}
