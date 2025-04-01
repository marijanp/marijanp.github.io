let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [
      (final: prev: {
        nodejs-16_x = final.nodejs;
        npmlock2nix = pkgs.callPackage sources.npmlock2nix { };
      })
      (import ./overlay.nix)
    ];
  };
in
{
  inherit (pkgs) dist;
  devShell = pkgs.mkShell {
    inputsFrom = [ pkgs.dist ];
    nativeBuildInputs = [
      pkgs.simple-http-server
      pkgs.nodejs
    ];
  };
}
