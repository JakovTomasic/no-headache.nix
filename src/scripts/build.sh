#!/usr/bin/env bash

# Pass output dir path as internal arguemnt
# This must be run from the path that the --config parametar is relative to
# --internal-out-link must be provided

# Default values
TRACE_OPTION=""
CONFIG_OPTION=".#"

USAGE_MESSAGE="Usage: nohead build [-c|--config <./path/to/flake/dir#config-name>] [--show-trace]"

GENERATE_DISK_IMAGES="false"

# --internal-out-link must be provided
OUT_LINK_PATH=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --internal-out-link)
      OUT_LINK_PATH="$2"
      shift 2
    ;;
    -c|--config)
      CONFIG_OPTION="$2"
      shift 2
    ;;
    --show-trace)
      TRACE_OPTION="--show-trace"
      shift 1
    ;;
    -h|--help|help|h)
      echo $USAGE_MESSAGE
      exit 1
    ;;
    *)
      echo "Unknown option: $1"
      echo $USAGE_MESSAGE
      exit 1
    ;;
  esac
done

echo "Using config option: $CONFIG_OPTION"
echo "Result link path: $OUT_LINK_PATH"

# Overwrite nix path to use flake version, fixing <nixpkgs>
nix --extra-experimental-features nix-command --extra-experimental-features flakes build $CONFIG_OPTION $TRACE_OPTION --out-link "$OUT_LINK_PATH"

