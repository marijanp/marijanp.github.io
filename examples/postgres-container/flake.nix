{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    inputs@{ nixpkgs, ... }:
    {
      nixosConfigurations = {
        postgres-container = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              { pkgs, config, ... }:
              let
                cfg = {
                  pgUser = "helloworld";
                  pgUserPassword = "helloworld";
                  # hash = $(echo -n "<pgUser><pgUserPassword>" | md5sum)
                  # prefix with md5 i.e. "md5$hash"
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

                networking.firewall.allowedTCPPorts = [ config.services.postgresql.settings.port ];

                services.postgresql = {
                  enable = true;
                  enableTCPIP = true;
                  settings.port = 5432;
                  ensureDatabases = [ cfg.pgDb ];
                  authentication = ''
                    #type database DBuser origin-address auth-method
                    # ipv4
                    host  all      ${cfg.pgUser}     0.0.0.0/0      md5
                    # ipv6
                    host all       ${cfg.pgUser}     ::/0           md5
                  '';
                  ensureUsers = [
                    {
                      name = cfg.pgUser;
                      ensureDBOwnership = true;
                    }
                  ];
                  initialScript = pkgs.writeText "backend-init-script" ''
                    CREATE ROLE ${cfg.pgUser} WITH SUPERUSER LOGIN PASSWORD '${cfg.pgUserPasswordMd5}' CREATEDB;
                  '';
                };
              }
            )
          ];
        };
      };
    };
}
