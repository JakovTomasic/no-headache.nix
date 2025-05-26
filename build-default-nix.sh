#!/usr/bin/env bash

# For debugging (in default.nix return attr set and you can see it with this command):
nix-shell -p jq --run "nix-instantiate --eval --json --strict | jq"

nix-build
./result/bin/build
