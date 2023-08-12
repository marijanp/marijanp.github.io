---
title: NixOS - How to add a Qemu image of a NixOS-Configuration as a flake output
author: Marijan
description: Learn to how add a Qemu image of your NixOS-Configuration as a flake output.
---
To create a Qemu image of a NixOS-Configuration you can use a function called <a class="link" href="https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix)">make-disk-image</a> in the following way:

```nix
{
  description = "My Qemu images";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  };

  outputs = { self, nixpkgs }: {
    qemu-image =
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
      in
      # see https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix
      # for an overview of available parameters
      import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
        inherit pkgs lib;
        format = "qcow2";
        diskSize = "8000";
        config = (import "${nixpkgs}/nixos/lib/eval-config.nix" {
          inherit pkgs system;
          modules = [
            nixpkgs.nixosModules.notDetected
            "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
            ({ pkgs, ... }: {
              fileSystems."/".device = "/dev/disk/by-label/nixos";
              boot.loader.grub.device = "/dev/vda";
              boot.loader.timeout = 0;
              users.extraUsers.root.password = "";
              system.stateVersion = "22.05";
              imports = [
                ./nixos-configuration.nix
              ];
            })
          ];
        }).config;
      };
  };
}
```
