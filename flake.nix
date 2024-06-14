{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
    website-builder.url = "git+https://git.sr.ht/~marijan/website-builder";
  };

  outputs = inputs@{ flake-parts, treefmt-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem = { self', inputs', pkgs, lib, ... }:
        {
          treefmt = {
            projectRootFile = ".git/config";
            programs.nixpkgs-fmt.enable = true;
          };

          apps.gh-deploy = {
            type = "app";
            program = "${lib.getExe (pkgs.writeShellApplication {
              name = "gh-deploy";
              runtimeInputs = [ pkgs.coreutils ];
              text = ''
                cp --no-preserve=mode -r ${self'.packages.dist}/* docs
              '';
            })}";
          };

          apps.srht-deploy = {
            type = "app";
            program = "${lib.getExe (pkgs.writeShellApplication {
              name = "srht-deploy";
              runtimeInputs = with pkgs; [ coreutils gnutar gnupg curl ];
              text = ''
                echo "Decrypting access-token"
                TOKEN=$(gpg --decrypt ${./secrets/sourcehut-pages-access-token.gpg})
                echo "Compressing website data (docs directory) ..."
                tar -C ${self'.packages.dist} -cvz . > site.tar.gz
                echo "Deploying website ..."
                curl --oauth2-bearer "$TOKEN" \
                  -Fcontent=@site.tar.gz \
                  https://pages.sr.ht/publish/marijan.pro
                rm site.tar.gz
                echo "Done."
              '';
            })}";
          };
          packages = {
            dist =
              let
                npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
              in
              pkgs.runCommand "dist" { LANG = "en_US.UTF-8"; nativeBuildInputs = [ pkgs.nodePackages.tailwindcss ]; } ''
                mkdir -p $out
                cp -r ${./src}/* .
                ${lib.getExe inputs'.website-builder.packages.default} build
                cp -r docs/* $out/
                export NODE_PATH=${npmlock2nix.v2.node_modules { src = ./.; nodejs = pkgs.nodejs; }}/node_modules
                cd $out
                tailwindcss -c ${./tailwind.config.js} -i css/style.css -o css/style.css
              '';
          };
        };
    };
}
