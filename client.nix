{ config, pkgs, ... }:

{
  imports = [ ./configuration.nix ];

  environment.etc."client.py".source = ./client.py;

  custom.pythonScript = "/etc/client.py";
  custom.hostName = "client";
}

