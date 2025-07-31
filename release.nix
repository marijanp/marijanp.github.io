let

  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  getSource = inputName: fetchTarball
    (
      let input = flakeLock.nodes.${inputName}.locked;
      in
      {
        url = input.url
          or "https://github.com/${input.owner}/${input.repo}/archive/${input.rev}.tar.gz";
        sha256 = input.narHash;
      }
    );
  pkgs = import (getSource "nixpkgs") {
    overlays = [
      (final: prev: {
        nodejs-16_x = final.nodejs;
        npmlock2nix = pkgs.callPackage (getSource "npmlock2nix") { };
      })
      (import ./overlay.nix)
    ];
  };
in
{
  inherit (pkgs) dist;
  devShell = pkgs.mkShell {
    inputsFrom = [ pkgs.dist ];
    packages = with pkgs; [
      simple-http-server
      nodejs
      nixpkgs-fmt
      gh-deploy
      srht-deploy
    ];
  };
}
