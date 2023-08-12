---
title: NixOS - A PostgreSQL NixOS container (not Docker)
author: Marijan
description: Enhance Database Development with Rust sqlx and PostgreSQL using NixOS Containers. Benefit from streamlined dependency management, reduced system impact, and enhanced reproducibility. Learn how NixOS containers compare to conventional setups and Docker-like technologies. Find a detailed instruction on creating and running a NixOS container instance.
---

Recently, I was trying out several different database driver implementations for Rust. [sqlx](https://github.com/launchbadge/sqlx">sqlx) sounded especially interesting to me since it enables compile-time verification of queries against the present database-schema state (produced by a series of migrations).

However, this powerful feature does come with a trade-off: the necessity of maintaining an active [PostgreSQL](https://www.postgresql.org/) server that the verifier can communicate with.

In contrast to the conventional approach of enabling a PostgreSQL service system-wide, I opted to leverage the capabilities of [NixOS containers](https://nixos.wiki/wiki/NixOS_Containers).

If you have experience with [Docker](https://www.docker.com/) or comparable technologies, you'll discover that NixOS containers represent an enhanced solution compared to their counterparts.
NixOS containers bring advantages like streamlined dependency management, reduced impact on your system (leveraging [systemd-nspawn](https://wiki.archlinux.org/title/systemd-nspawn">systemd-nspawn)), declarative configuration, and the ability to ensure reproducibility.
To delve deeper into the benefits of Nix, visit the official [Nix & NixOS website](https://nixos.org/).

In the remainder of this post I'll explain what I did to obtain a running NixOS container instance serving a PostgreSQL service.
I've created a new flake output in my projects flake called `nixosConfigurations.postgres-container`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations = {
        postgres-container = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ pkgs, config, ... }:
              let
                cfg = {
                  pgUser = "helloworld";
                  pgUserPassword = "helloworld";
                  pgUserPasswordMd5 = "md58be363cf63c20050aaad7dbe737acd73";
                  pgDb = "helloworld";
                };
              in
              {
                boot.isContainer = true;

                users.users.${cfg.pgUser} = {
                  name = cfg.pgUser;
                  group = cfg.pgUser;
                  isSystemUser = true;
                };

                users.groups.${cfg.pgUser} = { };

                networking.firewall.allowedTCPPorts =
                  [ config.services.postgresql.port ];

                services.postgresql = {
                  enable = true;
                  enableTCPIP = true;
                  port = 5432;
                  ensureDatabases = [ cfg.pgDb ];
                  authentication = ''
                    #type database DBuser origin-address auth-method
                    # ipv4
                    host  all      ${cfg.pgUser}     0.0.0.0/0      md5
                    # ipv
                    host all       ${cfg.pgUser}     ::/0           md5
                  '';
                  ensureUsers = [
                    {
                      name = cfg.pgUser;
                      ensurePermissions = {
                        "DATABASE \"${cfg.pgDb}\"" = "ALL PRIVILEGES";
                      };
                    }
                  ];
                  initialScript = pkgs.writeText "backend-init-script" ''
                    CREATE ROLE ${cfg.pgUser} WITH SUPERUSER LOGIN PASSWORD '${cfg.pgUserPasswordMd5}' CREATEDB;
                  '';
                };
              })
          ];
        };
      };
    };
}
```

After adding this output you can use it in the following way using `nixos-container`:

1. Create a container called "postgres", using the `nixosConfiguration.postgres-container` output of the current flake:

```bash
sudo nixos-container create postgres --flake .#postgres-container
```

2. Start the container

```bash
sudo nixos-container start postgres
```

3. If not printed after startup, run the following to figure out the containers IP address.

```bash
sudo nixos-container show-ip postgres
```

4. Test whether you can connect to the database that is running on the guest on your host. (other connection info was extracted from the `cfg` attrset, see flake output `postgres-container`)

```bash
psql -h <IP address from step 3> -p 5432 -d helloworld -U helloworld -W
```

`-W` will ask you for the password, which is `cfg.pgUserPassword` i.e. `helloworld`.

For obvious reasons you should not use this container in production.
