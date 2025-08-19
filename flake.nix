{
  description = "Main flake for the whole project with a dev shell encapsulating needed files and executables";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      # When this repo is downloaded from GitHub (or run locally) this is path to access all the files (in the nix store or locally on the system).
      absPath = ./.;

      buildConfig = { configsFile, makeDiskImages }: (
        import ./src/build.nix {
          userConfigsFile = configsFile;
          generateDiskImages = makeDiskImages;
          inherit pkgs system;
        }
      );

      dependencies = with pkgs; [
        qemu        # for running VMs
        procps      # for ps, kill, top, uptime, etc.
        gnugrep     # GNU grep
        gawk        # GNU awk
        bash        # In case the system doesn't already have bash for some weird reason
        # openssh   # ssh needs to be setup on the host device (because the deamon needs to be running, not just installed)
        git-crypt   # for secrets/ dir
      ];
    in {
      packages = let
        mainScript = pkgs.writeShellApplication {
          name = "nohead";
          runtimeInputs = dependencies;
          text = ''
            export NIX_STORE_ABS_PATH="${absPath}"
            "${absPath}/src/scripts/main.sh" "$@"
          '';
        };
      in {
        default = mainScript;
        nohead = mainScript;

        test-configs = buildConfig {
          configsFile = ./test/configs.nix;
          makeDiskImages = false;
        };
        test-configs-images = buildConfig {
          configsFile = ./test/configs.nix;
          makeDiskImages = true;
        };

        # examples (put here just for easier testing)
        copy-to-home = buildConfig {
          configsFile = ./examples/copy-to-home/configs.nix;
          makeDiskImages = false;
        };
        disk-images = buildConfig {
          configsFile = ./examples/disk-images/configs.nix;
          makeDiskImages = true;
        };
        python = buildConfig {
          configsFile = ./examples/python/configs.nix;
          makeDiskImages = false;
        };
        server-client = buildConfig {
          configsFile = ./examples/server-client/configs.nix;
          makeDiskImages = false;
        };
        shared-dir = buildConfig {
          configsFile = ./examples/shared-dir/configs.nix;
          makeDiskImages = false;
        };
        ssh-from-host = buildConfig {
          configsFile = ./examples/ssh-from-host/configs.nix;
          makeDiskImages = false;
        };
        vm-count-option = buildConfig {
          configsFile = ./examples/vm-count-option/configs.nix;
          makeDiskImages = false;
        };
      };

      # So users can run `nix run .#nohead`
      apps = {
        nohead = {
          type = "app";
          program = "${self.packages.${pkgs.system}.nohead}/bin/nohead";
        };
        default = self.apps.${pkgs.system}.nohead;
      };

      devShells = let
        nohead = pkgs.mkShell {
          packages = dependencies ++ [ self.packages.${pkgs.system}.nohead ];
          shellHook = ''
            echo "Dev shell loaded."
          '';
        };
      in {
        tailscale = import ./devshells/tailscale/devshell.nix { inherit pkgs; };
        nohead = nohead;
        default = nohead;
      };
    }
  );
}

