{
  description = "Auto-generated user flake in the root directory of your no-headache project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    no-headache.url = "github:JakovTomasic/no-headache.nix";
  };

  outputs = { self, nixpkgs, flake-utils, no-headache }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      buildConfig = { configsFile, makeDiskImages, customArgs ? {} }: (
        import "${no-headache}/src/build.nix" {
          userConfigsFile = configsFile;
          generateDiskImages = makeDiskImages;
          inherit pkgs system customArgs;
        }
      );
    in {
      packages = {
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
          customArgs = {
            customStringFromFlake = "This string is defined in the flake.nix";
          };
        };

        # This file was automatically generated on 'nohead init'.
        # Use it for your configurations.
        default = buildConfig {
          configsFile = ./configs.nix;
          makeDiskImages = false;
        };

        # NOTE: you can add add more configs here
      };

      devShells = {
        tailscale = no-headache.devShells.${system}.tailscale;
        nohead = no-headache.devShells.${system}.nohead;
        default = no-headache.devShells.${system}.default;
      };
    }
  );
}
