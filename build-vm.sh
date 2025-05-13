#!/usr/bin/env bash
rm -f nixos-vm.qcow2
nix run nixpkgs#nixos-rebuild -- build-vm -I nixos-config=./configuration.nix
