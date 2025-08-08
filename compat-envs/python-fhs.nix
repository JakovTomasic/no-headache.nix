# For instructions see README.md
{ pkgs ? import <nixpkgs> {} }:
let
  base = pkgs.appimageTools.defaultFhsEnvArgs;
in
pkgs.buildFHSEnv (base // {
  name = "python-fhs";
  targetPkgs = pkgs: with pkgs; [
    gcc
    glibc
    zlib
    # NOTE: add more dependencies here if you get a missing dependencies error

    (python3.withPackages (python-pkgs: with python-pkgs; [
        # Add all python packages you want here, if not using requirements.txt
        # For package names use search: https://search.nixos.org/packages
        # And write name here without prefix like python312Packages or python313Packages
        # example:
        # numpy
    ]))
    python3Packages.pip

    (pkgs.writeShellScriptBin "init-python-venv" ''
      # This script creates python venv (if needed) in the current directory.
      # It also has an option to install all packages from given requirements.txt file.
      # This script is run in a new bash script and cannot enter venv for you.

      USAGE_MESSAGE=$(cat <<EOF
Usage: $0 [-r|--requirements <file>]

After running this script you'll have to manually enter the environment by running source venv/bin/activate

This script essentialy runs:
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt # only if requirements file is defined
deactivate

Options:
  -r, --requirements <file>   Specify the requirements file. Recommended to use requirements.txt
  -h, --help                  Display this help message
EOF
      )
      REQ_FILE_NAME=""

      # Parse arguments
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          -r|--requirements)
            REQ_FILE_NAME="$2"
            shift 2
          ;;
          -h|--help)
            echo "$USAGE_MESSAGE"
            exit 1
          ;;
          *)
            echo "Unknown option: $1"
            echo "$USAGE_MESSAGE"
            exit 1
          ;;
        esac
      done


      if [[ ! -e "venv" ]]; then
        echo "venv doesn't exist in directory `pwd`. Creating venv."
        python -m venv venv
      fi

      if [[ -n $REQ_FILE_NAME ]]; then
        source venv/bin/activate
        pip install -r $REQ_FILE_NAME
        deactivate
      fi

      echo "venv setup completed"
    '')
  ];
  runScript = "bash";
  extraOutputsToInstall = [ "dev" ];
})
