{ lib, ... }:
{
  options = {
    configName = lib.mkOption {
      type = lib.types.str;
      description = "An unique name of the config defined in configs.nix with added index when count > 1. By default, this also defines networking.hostName";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "nixy";
      description = "Name of the main user";
    };

    tailscaleAuthKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "A file with Tailscale auth key value (and nothing else). Providing null means tealscale is disabled.";
    };

    firstHostSshPort = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "If null, host cannot connect to the VM without VPN. This defines the first SSH port for this VM type. If count is greather than one then each instance will have the next int as it's SSH port. No two VMs can have the same port.";
    };

    count = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of virtual machines to create";
    };

    nixos-config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Pass-through NixOS configuration. But don't use virtualisation configuration options here. Use nixos-config-virt instead.";
    };

    nixos-config-virt = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Pass-through NixOS configuration only for virtualized instances (VM builds, not for disk images). Overwrites values from nixos-config.";
    };

    init = {
      script = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "A bash script that's executed only once - when the environment starts.";
      };
    };

    copyToHome = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = ''
        Copies files and directories from host machine to desired location in the VM, relative to user home directory.
        This copies the files to the nix store and in VM creates symlinks to the nix store copy.
        That means **the files are read-only**. To modify the files just copy them in the VM (e.g. you can add in your init.script 'cp code.py code2.py' where code.py is symlink to a read-only file and code2.py is a normal read/write file).
        In the attr set, left (key) is destination string path (in quotes) in the VM relative to the home directory, right (value) is a path (without quotes) relative to the configs.nix file in which the path is written or absolute path. There may be any number of files or directories.
      '';
      example = {
        "code.py" = ./python/code.py;
        "config/settings.json" = /etc/second-file-path/settings.json;
      };
    };

    diskImage = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = "Null to disable making a disk image for this configurations. Otherwise, set parameters for make-disk-image.nix (see https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix). This option ignores count option - only one image per configuration will be built. Note: the disk image won't be built unless 'makeDiskImages = true' is set in your flake.nix file for the chosen config.";
    };

    # Options for internal use. Don't use them in your user configurations (configs.nix).
    internal = {
      baseConfigName = lib.mkOption {
        type = lib.types.str;
        description = "Base name of the config defined in configs.nix without added indexing";
      };
      index = lib.mkOption {
        type = lib.types.number;
        description = "Index of this machine. From 1 to count, including.";
      };
      hostSshPort = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "If null, host cannot connect to the VM without VPN. This defines the SSH port host will forward to this VM. This is computed from firstHostSshPort and index.";
      };
    };
  };
}

