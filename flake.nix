{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    horizon-platform.url = "git+https://gitlab.homotopic.tech/horizon/horizon-platform";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      imports = [
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          haskellPackages = 
            with pkgs.haskell.lib.compose; inputs'.horizon-platform.legacyPackages.extend
              (self: _: {
                lrucache = self.callHackage "lrucache" "1.2.0.1" { };
                time-locale-compat = self.callHackage "time-locale-compat" "0.1.1.5" { };
                hakyll = doJailbreak (self.callHackage "hakyll" "4.15.1.1" { });
                website = self.callCabal2nix "website" ./. { };
              });
        in
        {
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
