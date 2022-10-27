---
title: haskell.nix - How to reliably add runtime dependencies
author: Marijan
---

Assuming you use `haskell.nix` and have created a Haskell program that requires another executable to be present in the environment i.e. the `PATH` variable.

Using Nix, you can [wrap](https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages) your executable ([related post](/posts/2022-06-03-dont-override-and-wrap-only.html)), which is the standard technique to ensure that your program will be distributed together with that executable.

This standard approach, in combination with `haskell.nix`, could look like this:

```
{
  description = "naive";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskellNix.url = "github:input-output-hk/haskell.nix/112669d1ba96fa2a1c75478d12d6f38ee2bd3ee6";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  };

  outputs = { self, flake-parts, nixpkgs, haskellNix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          projectName = "example";

          overlays = [
            haskellNix.overlay
            (final: prev: {
              ${projectName} = final.haskell-nix.cabalProject {
                src = ../example;
                compiler-nix-name = "ghc924";
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.${projectName}.flake { };

          wrappedExample = pkgs.runCommand "demo-wrapped-better"
            {
              buildInputs = [ pkgs.makeWrapper ];
            }
            ''
              mkdir -p $out/bin
              makeWrapper ${self'.packages."example:exe:example"}/bin/example $out/bin/example \
                --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
            '';
        in
        # remove attributes which are not supported by flake-parts
        pkgs.lib.recursiveUpdate
          (builtins.removeAttrs haskellNixFlake [ "devShell" "hydraJobs" ])
          {
            devShells.default = haskellNixFlake.devShell;

            apps.example = {
              type = "app";
              program = "${wrappedExample}/bin/example";
            };
          };
    };
}
```

We unify the `haskell.nix`-generated `flake` attribute set that contains: the generated library, executable, and test outputs, with our flake output attribute set, which in turn outputs the wrapped app called `example`.

Running `nix flake show --allow-input-from-derivation` we get the following output:
```
├───apps
│   └───x86_64-linux
│       ├───example: app
│       ├───"example:exe:example": app
│       └───"example:test:example-test": app
├───checks
│   └───x86_64-linux
│       └───"example:test:example-test": derivation 'example-test-example-test-0.1.0.0-check'
├───darwinModules: unknown
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'ghc-shell-for-example'
├───formatter
├───legacyPackages
│   └───x86_64-linux omitted (use '--legacy' to show)
├───nixosConfigurations
├───nixosModules
├───overlays
└───packages
    └───x86_64-linux
        ├───"example:exe:example": package 'example-exe-example-0.1.0.0'
        ├───"example:lib:example": package 'example-lib-example-0.1.0.0'
        └───"example:test:example-test": package 'example-test-example-test-0.1.0.0'
```

These flake outputs we get from `haskell.nix` are desirable as we don't want to define everything ourselves. And this brings the problem to the surface when we use the standard approach to wrap our executable: take a closer look at the outputs!

Some flake outputs are not wrapped with the required runtime dependencies, namely `apps.x86_64-linux."example:exe:example"` and `packages.x86_64-linux."example:exe:example"`.

Since we do not want users to accidentally use one of the output executables without all the required runtime dependencies, we would need to replace all the unwrapped executable outputs with the wrapped executable.
That means removing the attribute from `haskell.nix's` flake outputs and redefining them in our flake outputs.

This process of removing and adding new outputs is very error-prone. And it gets tedious the more apps our potentially huge monorepo exports. It would be better if `haskell.nix` would take our runtime dependencies into account when generating the flake outputs.

Fortunately, we can do that using `haskell.nix's` module options:
```
{
  description = "better";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";
    haskellNix.url = "github:input-output-hk/haskell.nix/112669d1ba96fa2a1c75478d12d6f38ee2bd3ee6";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  };

  outputs = { self, flake-parts, nixpkgs, haskellNix, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          projectName = "example";

          overlays = [
            haskellNix.overlay
            (final: prev: {
              ${projectName} = final.haskell-nix.cabalProject {
                src = ../example;
                compiler-nix-name = "ghc924";
                modules = [
                  {
                    packages = {
                      example.components.exes.example = {
                        build-tools = [ pkgs.makeWrapper ];
                        postInstall = ''
                          wrapProgram $out/bin/example --set PATH ${pkgs.lib.makeBinPath [ pkgs.hello ]}
                        '';
                      };
                    };
                  }
                ];
              };
            })
          ];
          pkgs = import nixpkgs { inherit system overlays; };
          haskellNixFlake = pkgs.${projectName}.flake { };
        in
        pkgs.lib.recursiveUpdate
          (builtins.removeAttrs haskellNixFlake [ "devShell" "hydraJobs" ]) # remove attributes which are not supported by flake-parts
          {
            devShells.default = haskellNixFlake.devShell;
          };
    };
}
```

This way, the generated `haskell.nix` flake output will contain our wrapped executables reliably without the extra work of redefining outputs.

The working flakes and the `example` Cabal package can be found [here](https://git.sr.ht/~marijan/website/tree/main/item/examples/haskell-nix/wrap).

