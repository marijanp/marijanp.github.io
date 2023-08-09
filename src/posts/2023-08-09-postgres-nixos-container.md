---
title: NixOS - A PostgreSQL NixOS-Container
author: Marijan
---

Recently, I was trying out several different database driver implementations for Rust. [sqlx](https://github.com/launchbadge/sqlx) sounded especially interesting to me since it enables compile-time verification of queries against the current database-schema state (produced by a series of migrations).

But this feature comes with a price: I need to have a [PostgreSQL](https://www.postgresql.org/) server running, that the verifier can connect to.

Instead of polluting my system by enabling the service, I decided to use NixOS containers.

I've created a new flake output in my projects flake and added the following:

```nix
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

          networking.firewall.allowedTCPPorts = [ config.services.postgresql.port ];

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
```

After adding this output you can use it in the following way using `nixos-container`:
</br>

1. Create a container called "postgres":

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

</br>

For obvious reasons you should not use this container in production.
