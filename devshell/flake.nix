{
  description = "Dev shell encapsulating needed files and executables";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: 
    let
      # TODO: make configurable?
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Define a derivation that includes your files
      myFiles = pkgs.stdenv.mkDerivation {
        name = "my-files";
        src = ./.;

        installPhase = ''
          mkdir -p $out/bin
          # cp $src/build.sh $out/bin/
          # cp $src/run-all.sh $out/bin/
          # cp $src/build-and-run-all.sh $out/bin/

          cp $src/base-configuration.nix $out/
          cp $src/default.nix $out/
          cp $src/options.nix $out/
          '';
      };
      printFilesPath = pkgs.writeShellScriptBin "printFilesPath" ''
        echo "${myFiles}"
      '';
      build = pkgs.writeShellScriptBin "buildVms" ''
        # Default values
        CONFIG_FILE="./configs.nix"
        SECRETS_DIR="./secrets"

        USAGE_MESSAGE="Usage: $0 [-c|--config <file>] [-s|--secrets <file>]"

        # Parse arguments
        while [[ "$#" -gt 0 ]]; do
          case "$1" in
            -c|--config)
              CONFIG_FILE="$2"
              shift 2
              ;;
            -s|--secrets)
              SECRETS_DIR="$2"
              shift 2
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
        echo "Using secrets dir: $SECRETS_DIR"

        nix-build ${myFiles}/default.nix --arg userConfigsFile "$CONFIG_FILE" --arg secretsDir "$SECRETS_DIR"
      '';
      runAll = pkgs.writeShellScriptBin "runAllVms" ''
        ./result/bin/runAll
      '';
      buildAndRun = pkgs.writeShellScriptBin "buildAndRun" ''
        buildVms && runAllVms
      '';
    in {
      devShells.${system}.default = pkgs.mkShell {
        # myFiles $out/bin will be automatically added to the path
        packages = [ myFiles build runAll buildAndRun printFilesPath ];

        shellHook = ''
          echo "Dev shell loaded."
        '';
      };
    };
}

