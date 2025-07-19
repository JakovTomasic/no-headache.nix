#!/usr/bin/env bash

# Enter the main (default) nix dev shell
# You may run this script from anywhere.

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# exec replaces this bash process with the nix develop shell.
# That eliminates one dangling bash process just waiting for nix develop to finish.
exec nix develop "$SCRIPT_DIR/"

