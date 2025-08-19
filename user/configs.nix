{ pkgs, ... }:
let
in
{
  empty = {
    # Change count of this config named "empty"
    count = 1;
    nixos-config = {
      # Install python3
      environment.systemPackages = with pkgs; [ python3 ];

      # Use any other NixOS options here
    };
  };

  # Add new configurations here
}

