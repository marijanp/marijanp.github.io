let
  sources = import ./nix/sources.nix { };

  haskellNix = import sources.haskellNix { };
  pkgs = import haskellNix.sources.nixpkgs-unstable haskellNix.nixpkgsArgs;

  haskellPkgs = pkgs.haskell-nix.cabalProject {
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "marijanp-github-io";
      src = ./.;
    };
    compiler-nix-name = "ghc8107";
  };
in
{
  inherit (haskellPkgs.marijanp-github-io.components.exes) site;

  dev-shell = haskellPkgs.shellFor {
    withHoogle = false;
    tools = {
      cabal = "latest";
      hlint = "latest";
      haskell-language-server = "latest";
    };

    buildInputs = with pkgs; [
      haskellPackages.hakyll
    ];
    exactDeps = true;
  };
}
