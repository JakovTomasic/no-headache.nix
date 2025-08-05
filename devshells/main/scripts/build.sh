#!/usr/bin/env bash

# Pass output dir path as internal arguemnt
# This must be run from the path that the --config parametar is relative to

# Default values
CONFIG_FILE="./configs.nix"
TRACE_OPTION=""

USAGE_MESSAGE="Usage: $0 [-c|--config <file>] [--images] [--show-trace]"

GENERATE_DISK_IMAGES="false"

OUT_LINK_PATH="$NO_HEADACHE_PROJECT_ROOT_DIR/result"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --internal-out-link)
      OUT_LINK_PATH="$2"
      shift 2
    ;;
    -c|--config)
      CONFIG_FILE="$2"
      shift 2
    ;;
    --images)
      GENERATE_DISK_IMAGES="true"
      shift 1
    ;;
    --show-trace)
      TRACE_OPTION="--show-trace"
      shift 1
    ;;
    -h|--help)
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

# Convert CONFIG_FILE to absolute path because cd will be run later
CONFIG_FILE_NAME="$(basename $CONFIG_FILE)"
CONFIG_FILE="$(cd "$(dirname $CONFIG_FILE)" && pwd)/$CONFIG_FILE_NAME"
echo "Using config file: $CONFIG_FILE"
echo "Result link path: $OUT_LINK_PATH"

# Enter the directory so that flake is in the current directory
cd "$NO_HEADACHE_PROJECT_ROOT_DIR"
# Overwrite nix path to use flake version, fixing <nixpkgs>
NIX_PATH="nixpkgs=flake:nixpkgs" nix --extra-experimental-features nix-command --extra-experimental-features flakes build -f "$NIX_STORE_ABS_PATH/devshells/main/default.nix" --arg userConfigsFile $CONFIG_FILE --arg generateDiskImages $GENERATE_DISK_IMAGES --argstr system "$SYSTEM_NAME" $TRACE_OPTION --out-link "$OUT_LINK_PATH"


