{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/8a2f738d9d1f1d986b5a4cd2fd2061a7127237d7";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    npmlock2nix.url = "github:nix-community/npmlock2nix/9197bbf397d76059a76310523d45df10d2e4ca81";
    npmlock2nix.flake = false;
  };

  outputs = { self, nixpkgs, npmlock2nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            nodejs-16_x = final.nodejs;
            npmlock2nix = pkgs.callPackage npmlock2nix { };
          })
          (import ./overlay.nix)
        ];
      };
    in
    {
      overlays.default = import ./overlay.nix;

      apps.${system} = {
        gh-deploy = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.gh-deploy}";
        };

        srht-deploy = {
          type = "app";
          program = "${pkgs.lib.getExe pkgs.srht-deploy}";
        };
      };

      packages.${system} = {
        inherit (pkgs) dist;
        default = self.packages.${system}.dist;
      };
    };
}
