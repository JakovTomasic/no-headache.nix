#!/usr/bin/env bash
rm -f client.qcow2
rm -f server.qcow2

nix run nixpkgs#nixos-rebuild -- build-vm -I nixos-config=./client.nix
rm -rf result-client
mv result result-client

nix run nixpkgs#nixos-rebuild -- build-vm -I nixos-config=./server.nix
rm -rf result-server
mv result result-server
