let
  sources = import ./npins;
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
    nativeBuildInputs = with pkgs; [
      simple-http-server
      nodejs
      nixpkgs-fmt
      gh-deploy
      srht-deploy
    ];
  };
}
