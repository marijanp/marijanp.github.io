{
  description = "marijan's website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c043004d1c6985732bcc1cbc5a9c9aecbbb4e0f0";
    treefmt-nix.url = "github:numtide/treefmt-nix/27b3b12a8e6375f28ebe122f07d230ca5459bbfa";
    treefmt-nix.flake = false;
    npmlock2nix.url = "github:nix-community/npmlock2nix/4d9060afbaa5f57ee0b8ef11c7044ed287a7d302";
    npmlock2nix.flake = false;
  };

  outputs = { self, nixpkgs, npmlock2nix, treefmt-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            nodejs-16_x = final.nodejs;
            npmlock2nix = pkgs.callPackage npmlock2nix { };
            treefmt-nix = import treefmt-nix;
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
