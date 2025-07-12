{ lib, ... }:
{
  options = {
    configName = lib.mkOption {
      type = lib.types.str;
      description = "An uniqu name of the config defined in configs.nix with added index when count > 1. By default, this also defines netowrking.hostName";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "nixy";
      description = "Name of the main user";
    };

    tailscaleAuthKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "A file with Tailscale auth key value (and nothing else). Providing null means tealscale is diabled";
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
      description = "Pass-through NixOS configuration";
    };

    init = {
      script = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "A bash script that's executed only once - when the environment starts.";
      };
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

  # TODO: write assertions if needed (e.g. no config option for hostname and some other options)
  # _module.args = {
  #   myCustomConfig = customConfig;
  # };
  # config = {
  #   # Use it somewhere in your module
  #   assertions = [
  #     {
  #       assertion = myCustomConfig.count > 0;
  #       message = "count must be positive";
  #     }
  #   ];
  # };
}
