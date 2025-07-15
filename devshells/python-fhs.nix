# run this with nix develop -f ./python-fhs.nix
let
  # TODO: use real nixpkgs version? Will this work anyways?
  pkgs = import <nixpkgs> {};
  base = pkgs.appimageTools.defaultFhsEnvArgs;
in
pkgs.buildFHSEnv (base // {
  name = "FHS";
  targetPkgs = pkgs: with pkgs; [
    gcc
    glibc
    zlib
    (python3.withPackages (python-pkgs: with python-pkgs; [
        # Add all python packages you want here, if not using requirements.txt
        # For package names use search: https://search.nixos.org/packages
        # And write name here without prefix like python312Packages or python313Packages
        # numpy
    ]))
    python3Packages.pip
  ];
  # TODO: support requirements.txt
  runScript = "bash";
  extraOutputsToInstall = [ "dev" ];
})
