{ pkgs, ... }:
{
  client = {
    custom.pythonScript = "/etc/client.py";
    custom.hostName = "client";
    tailscaleAuthKeyFile = ./secrets/tailscale.authkey;
    nixos-config = {
      # users.users.nixy.extraGroups = [ "aaaaa" ];

      # Deploy the script into /etc/python-app/client.py
      # TODO: this may not work
      environment.etc."client.py".source = ./client.py;
    };
  };
  server = {
    custom.pythonScript = "/etc/server.py";
    custom.hostName = "server";
    tailscaleAuthKeyFile = ./secrets/tailscale.authkey;
    nixos-config = {
      # Deploy the script into /etc/python-app/server.py
      # TODO: this may not work
      environment.etc."server.py".source = ./server.py;
    };
  };
}

