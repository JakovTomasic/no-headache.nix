{ pkgs, system, absPath } :
let
  # Define a derivation that includes your files
  printFilesPath = pkgs.writeShellScriptBin "printFilesPath" ''
    echo "${absPath}"
  '';
  build = pkgs.writeShellScriptBin "buildVms" ''
    # Default values
    CONFIG_FILE="./configs.nix"
    TRACE_OPTION=""

    USAGE_MESSAGE="Usage: $0 [-c|--config <file>] [--images] [--show-trace]"

    GENERATE_DISK_IMAGES="false"

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
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

    echo "Using config file: $CONFIG_FILE"

    # Enter the directory so that flake is in the current directory
    cd "${absPath}"
    # Overwrite nix path to use flake version, fixing <nixpkgs>
    NIX_PATH="nixpkgs=flake:nixpkgs" nix --extra-experimental-features nix-command --extra-experimental-features flakes build -f devshells/main/default.nix --arg userConfigsFile $CONFIG_FILE --arg generateDiskImages $GENERATE_DISK_IMAGES --argstr system "${system}" $TRACE_OPTION
    '';
  runAll = pkgs.writeShellScriptBin "runAllVms" ''
    ./result/bin/runAll $@
  '';
  sshInto = pkgs.writeShellScriptBin "sshInto" ''
    ./result/bin/ssh-into-$1
  '';
  listAllRunningVMs = pkgs.writeShellScriptBin "listRunningVMs" ''
    ps aux | grep '[q]emu-system' | awk 'match($0, /-name ([^ ]+)/, m) { print m[1] }'
  '';
  stopVm = pkgs.writeShellScriptBin "stopVm" ''
    # Check for argument
    if [ -z "$1" ]; then
      echo "Usage: $0 <vm-name>"
      exit 1
    fi

    VM_NAME="$1"

    # Find PIDs of QEMU instances with the exact -name argument
    mapfile -t PIDS < <(
      ps aux | grep '[q]emu-system' | grep -w "\-name $VM_NAME" | awk '{print $2}'
    )

    NUM_PIDS=''${#PIDS[@]}

    if [ "$NUM_PIDS" -eq 0 ]; then
      echo "No running VM found with name: $VM_NAME"
      exit 1
    elif [ "$NUM_PIDS" -gt 1 ]; then
      echo "Multiple VMs found with name: $VM_NAME"
      printf 'Matched PIDs: %s\n' "''${PIDS[@]}"
      echo "Please write valid unique VM name."
      exit 1
    fi

    PID="''${PIDS[0]}"
    echo "Stopping VM '$VM_NAME' with PID $PID..."
    kill "$PID"
  '';

  # These packages are included in most Unix environments so installing new version of them might be an overhead.
  requirements = with pkgs; [
    procps   # for ps, kill, top, uptime, etc.
    gnugrep  # GNU grep
    gawk     # GNU awk
  ];
in
  pkgs.mkShell {
    packages = requirements ++ [ build runAll printFilesPath sshInto listAllRunningVMs stopVm ];

    shellHook = ''
      echo "Dev shell loaded."
    '';
  }
