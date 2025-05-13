{ config, pkgs, ... }:

{
  imports = [ ./configuration.nix ];

  # Deploy the script into /etc/python-app/server.py
  environment.etc."server.py".source = ./server.py;

  custom.pythonScript = "/etc/server.py";
  custom.hostName = "server";
}

