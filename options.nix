{ lib, ... }:
{
  options = {
    # TODO: only one path? Copy this? How does this work?
    custom.pythonScript = lib.mkOption {
      type = lib.types.str;
      description = "Path to the Python script to run.";
    };

    # TODO: optional, default to configName somehow
    custom.hostName = lib.mkOption {
      type = lib.types.str;
      description = "Network name";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the config defined in configs.nix";
    };

    nixos-config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Pass-through NixOS configuration";
    };

    # TODO: accept all other nixos config options (except hostname...)
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
