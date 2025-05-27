#!/usr/bin/env bash
# TODO: delete this script

# For debugging (in default.nix return attr set and you can see it with this command):
# You can also look at the generated config files
# nix-shell -p jq --run "nix-instantiate --eval --json --strict | jq"

nix-build
