---
title: NixOS - How to modify systemd services you don't own
author: Marijan
#https://nixos.org/manual/nixos/stable/#module-services-litestream-configuration
---
# The problem
I imported and enabled a NixOS module i.e. a systemd service, that listens on a socket.
The module options for the service allowed to specify the socket path manually and the application would take care of creating the socket at the given path.
This socket had read-only file permissions and the problem was, that another service that is supposed to communicate with the prior service through that socket
needed write permissions.

Neither of the two modules had options to configure the `group` or `user` of the service and I was stuck with the question:
"How to add write permissions for that socket without modifying the upstream module definitions?"

# Solution
Sometimes you think you know how `Nix` works, but for some reason the most obvious solutions just don't come to your mind.
Obviously the module system allows you to change configurations, and there is a configuration option for systemd services called `serviceConfig`.
So what I've ended up doing is the following:

`socket-listener` being the NixOs module i.e. systemd service that listens on a socket.
```
services.socket-listener = {
  enable = true;
  socketPath = "/run/socket-listener/socket-listener.socket";
};

systemd.services.socket-listener.serviceConfig.ExecStartPost = pkgs.writeShellScript "add-socket-write-permissions" ''
    while [ ! -S ${config.socket-listener.socketPath} ];
    do
      sleep 1
    done
    chmod 0666 ${config.socket-listener.socketPath}
  '';
```
