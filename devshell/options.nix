{ lib, ... }:
{
  options = {
    configName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the config defined in configs.nix. By default, this also defines netowrking.hostName";
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
