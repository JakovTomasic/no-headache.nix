#!/usr/bin/env bash

# This script should only be called from the main devshell script.
# The calles should export environment variables to be accessible in this script, too:
# - NIX_STORE_ABS_PATH (path to where the current devshell copied all the data)

SCRIPT_NAME="nohead"
INITIAL_USER_PATH="$(pwd)"
# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"



USAGE_MESSAGE=$(cat <<EOF
no-headache.nix is development and testing environment powered by the Nix package manager, allowing you to define and run declarative, reproducible, and isolated NixOS virtual machines (VMs) and disk images with minimal setup.

Usage: $SCRIPT_NAME [options] <subcommand> [command flags]

The <vm-name> values are names defined in your configs.nix file:
- if count = 1 (or not specified) they're equal to defined name
- otherwise they have a format of name-<index> where index is in range [1, count] (including)

Subcommands:
  init
    Creates new no-headache project in a new directory and initializes everything.
  build
    Build VMs and disk images. Run '$SCRIPT_NAME build --help' for more info.
  run <vm-name>
    Start VM by its unique name (including the index). Make sure to run build before this.
  runall
    Start all VMs built in the last successful build.
  list
    List all running no-headache QEMU virtual machines, one per line.
  stop <vm-name>
    Stop the running virtual machine using its unique name.
  stopall
    Stops all running no-headache QEMU virtual machines.
  ssh <vm-name> [other standard ssh options...]
    SSH into a VM with provided unique name.
  path
    Print nix store path where the current devshell files are.
  help
    Print this message.
  h
    Print this message.

Options:
  -r | --result <result-dir-path>    Relative path to the generated result dir symlink to use, including the result link name (not just the parent directory).
                                     When using with build command that will be the output result link.
                                     When using with other commands, built result from that link will be used.
                                     Default: './result' (result directory in the current directory).
EOF
)

RESULT_DIR_PATH="$INITIAL_USER_PATH/result"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
case "$1" in
  -r|--result)
    cd "$INITIAL_USER_PATH"
    DIRNAME="$(dirname "$2")"
    if [ ! -f "$DIRNAME" ] && [ ! -d "$DIRNAME" ]; then
      echo "Error: directory doesn't exist: $DIRNAME"
      echo "Did you run $SCRIPT_NAME build"
      exit 1
    fi
    cd "$DIRNAME"
    RESULT_DIR_PATH="$(pwd)/$(basename "$2")"
    shift 2
  ;;
  init)
    OUTPUT_DIR_NAME="no-headache"

    cd "$INITIAL_USER_PATH" &&
    mkdir "$OUTPUT_DIR_NAME" &&
    cd "$OUTPUT_DIR_NAME" &&
    mkdir secrets &&
    cp "$NIX_STORE_ABS_PATH/user/flake.nix" . &&
    cp "$NIX_STORE_ABS_PATH/user/configs.nix" . &&
    cp "$NIX_STORE_ABS_PATH/flake.lock" . &&
    cp -r "$NIX_STORE_ABS_PATH/compat-envs" . &&
    cp -r "$NIX_STORE_ABS_PATH/examples" . &&
    # Change owner to the current user and make all file writeable (deletable)
    chown $(whoami) . -R &&
    chmod u+w . -R &&

    echo "New empty project generated in '$OUTPUT_DIR_NAME/'. You may rename the root directory." &&
    echo "Reminder: Add the directory to git if it's inside a git repository."

    exit 0
  ;;
  build)
    shift 1
    # cd into initial directory because config path is relative to it
    cd "$INITIAL_USER_PATH"
    "$SCRIPT_DIR/build.sh" --internal-out-link "$RESULT_DIR_PATH" $@
    exit 0
  ;;
  stop)
    "$SCRIPT_DIR/stop.sh" $2
    exit 0
  ;;
  stopall)
    "$SCRIPT_NAME" list | xargs -n1 "$SCRIPT_NAME" stop
    exit 0
  ;;
  path)
    echo "$NIX_STORE_ABS_PATH"
    exit 0
  ;;
  list)
    ps aux | grep '[q]emu-system' | awk 'match($0, /-name ([^ ]+)/, m) { print m[1] }'
    exit 0
  ;;
  ssh)
    if [ ! -f "$RESULT_DIR_PATH" ] && [ ! -d "$RESULT_DIR_PATH" ]; then
      echo "Error: Result directory doesn't exist: $RESULT_DIR_PATH"
      echo "Did you run $SCRIPT_NAME build"
      exit 1
    fi
    VM_NAME="$2"
    shift 2
    "$RESULT_DIR_PATH/bin/ssh-into-$VM_NAME" "$@"
    exit 0
  ;;
  runall|runAll|run-all)
    shift 1
    if [ ! -f "$RESULT_DIR_PATH" ] && [ ! -d "$RESULT_DIR_PATH" ]; then
      echo "Error: Result directory doesn't exist: $RESULT_DIR_PATH"
      echo "Did you run $SCRIPT_NAME build"
      exit 1
    fi
    "$RESULT_DIR_PATH/bin/runAll" $@
    exit 0
  ;;
  run)
    VM_NAME="$2"
    shift 2
    if [ ! -f "$RESULT_DIR_PATH" ] && [ ! -d "$RESULT_DIR_PATH" ]; then
      echo "Error: Result directory doesn't exist: $RESULT_DIR_PATH"
      echo "Did you run $SCRIPT_NAME build"
      exit 1
    fi
    "$RESULT_DIR_PATH/bin/$VM_NAME" $@
    exit 0
  ;;
  h|help|-h|--help|whatisgoingon)
    echo "$USAGE_MESSAGE"
    exit 0
  ;;
  *)
    echo "Unknown option: $1"
    echo "$USAGE_MESSAGE"
    exit 1
  ;;
esac
done

echo "No arguments provided"
echo ""
echo "$USAGE_MESSAGE"

