final: prev: {
  dist = final.callPackage ./default.nix { };
  gh-deploy = final.writeShellApplication {
    name = "gh-deploy";
    runtimeInputs = [ final.coreutils ];
    text = ''
      cp --no-preserve=mode -r ${final.dist}/* docs
    '';
  };
  srht-deploy = final.writeShellApplication {
    name = "srht-deploy";
    runtimeInputs = with final; [
      coreutils
      gnutar
      gnupg
      curl
    ];
    text = ''
      echo "Decrypting access-token"
      TOKEN=$(gpg --decrypt ${./secrets/sourcehut-pages-access-token.gpg})
      echo "Compressing website data (docs directory) ..."
      tar -C ${final.dist} -cvz . > site.tar.gz
      echo "Deploying website ..."
      curl --oauth2-bearer "$TOKEN" \
        -Fcontent=@site.tar.gz \
        https://pages.sr.ht/publish/marijan.pro
      rm site.tar.gz
      echo "Done."
    '';
  };
}
