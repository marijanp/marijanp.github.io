---
title: Don't use `wrapProgram` in `overrideAttrs` if you only want to wrap an executable
author: Marijan
---
Let's say you created a program that requires another executable to be present in your environment i.e. in the `PATH` variable.

Using Nix there is a way to ensure that your program will only be distributed together with that executable by wrapping your program.

E.g. we want a program named `demo` to be shipped with `hello`.

This is what I used to do:
```
demo = <some package>;
demo-wrapped = demo.overrideAttrs (oldAttrs: rec {
  buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
  postInstall = oldAttrs.postInstall or "" + ''
    wrapProgram $out/bin/demo \
      --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
  '';
});
```
Recently Matthew made me aware that my approach causes compilation of that executable to happen twice under certain circumstances.

The reason for that is that `overrideAttrs` per definition runs through all phases again just to run the new customized phase (in this example: `postInstall`).

If `demo` itself was not changed in any way but `demo-wrapped` was modified e.g. by logging a message stdout, nix would compile `demo` again just to run the updated `postInstall` phase instead of obtaining it either from a binary cache or from the local nix store.

To avoid this, a much better approach is to do the following:
```
demo-wrapped-better = pkgs.runCommand "demo-wrapped-better" {
  buildInputs = [ pkgs.makeWrapper ];
  }
  ''
      mkdir -p $out/bin
      makeWrapper ${demo}/bin/demo $out/bin/demo \
        --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
  '';
```

The reason that I used `overrideAttrs` was that I found an usage example of `makeWrapper` written like that in `nixpkgs` with a subtle difference I didn't recognize. For the example I found recompilation was inevitable because there was a change that caused the result of the compilation to change the binary completely. So the author decided to add `makeWrapper` along the way.

I would like to thank Matthew for taking his time to explain me this subtle issue.
