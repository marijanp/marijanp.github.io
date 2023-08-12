---
title: Nix - Avoid overrideAttrs when wrapping an executable
author: Marijan
description: Explore a nuanced issue with overrideAttrs causing unnecessary recompilations.
---
Let's say you created a program which requires another executable to be present in your environment i.e. in the `PATH` variable.

Using Nix, there is a way to ensure that your program will only be distributed together with that executable by wrapping it. 

E.g. we want a program named `demo` to be packaged such that `hello` is available in the `PATH`.

### Wrong solution

What I used to do was the following:
```nix
demo = <some package>;
demo-wrapped = demo.overrideAttrs (oldAttrs: rec {
  buildInputs = oldAttrs.buildInputs or [] ++ [ pkgs.makeWrapper ];
  postInstall = oldAttrs.postInstall or "" + ''
    wrapProgram $out/bin/demo \
      --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
  '';
});
```

But recently [Matthew](https://nix.how) made me aware that my approach causes compilation of the wrapped executable (`demo`) to occur twice under certain circumstances.

The reason for that is that `overrideAttrs` per definition runs through all phases again just to run the new customized phase (in this example: `postInstall`).

If `demo` itself was not changed in any way but `demo-wrapped` was modified e.g. by logging a message to stdout, Nix would compile `demo` again just to run the updated `postInstall` phase instead of obtaining it either from a binary cache or from the local Nix store.

The reason I used `wrapProgram` inside `overrideAttrs` was that I found an usage example of `makeWrapper` written like this in `nixpkgs` but with a subtle difference I didn't recognize. In the usage example from `nixpkgs` recompilation was inevitable because there was a change in `overrideAttrs` that caused the result of the compilation of the binary to change completely. So the author decided to add `makeWrapper` along the way.
For me this was not the case, therefore one should not use `overrideAttrs` just to wrap an executable.

### Better solution
To avoid the problem mentioned above, a much better approach is to do the following:
```nix
demo-wrapped-better = pkgs.runCommand "demo-wrapped-better" {
    buildInputs = [ pkgs.makeWrapper ];
  }
  ''
      mkdir -p $out/bin
      makeWrapper ${demo}/bin/demo $out/bin/demo \
        --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
  '';
```

I would like to thank [Matthew](https://nix.how">Matthew) for taking his time to explain me this subtle issue.
