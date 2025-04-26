<h1 id="title">NixOS - How to add a QEMU image of a NixOS-Configuration as a flake output</h1>
<p>
  <address>By <a rel="author">Marijan</a></address> on <time id="post-date" datetime="2022-09-26">2022-09-26</time>
</p>

<p id="excerpt">
  Learn to how add a QEMU image of your NixOS-Configuration as a flake output.
</p>

To create a QEMU image of a NixOS-Configuration you can use a function called [make-disk-image](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix) in the following way:

```nix
{
  description = "My QEMU images";
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
