let
  pkgs = import <nixpkgs> {};
  configBuilder = config: (import ./base-configuration.nix { inherit pkgs config; });

  # User defined configurations
  configs = import ./configs.nix {};
  # Generates nix configurations (effectively configuration.nix files)
  configurations = builtins.mapAttrs (name: value:
    configBuilder (pkgs.lib.evalModules {
      modules = [
        ./options.nix
        value
        {
          # TODO: maybe I don't need this
          configName = name;
        }
      ];
    }).config
  ) configs;


  # Scripts that run generated VMs
  runVmScripts = pkgs.lib.foldl' pkgs.lib.mergeAttrs {} (builtins.map (machine:
    {
      "${machine.name}" = pkgs.writeShellScriptBin "${machine.name}" ''
        echo "Running ${machine.name}"
        # TODO: run in background, don't block execution - provide options for that (as parameters to this script?)
        ${machine.vm-path}/bin/run-${machine.name}-vm &
      '';
    }
  ) builtNixosMachinesListWithNames);
  runVmScriptPaths = builtins.attrValues runVmScripts;

  # A script that runs all VMs at the same time
  runAllVmsScript = pkgs.writeShellScriptBin "build" ''
    ${builtins.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs (name: value: "${value}/bin/${name}") runVmScripts)
    )}
  '';

  # Generate nixos virtual machines (effectively the same as running nixos-rebuild -- build-vm)
  # TODO: pin version - there is a specific way how to do this with flakes?
  nixosSystem = import <nixpkgs/nixos/lib/eval-config.nix>;
  nixosMachines = builtins.attrValues (builtins.mapAttrs (name: c:
    {
      name = name;
      system = nixosSystem {
        system = "x86_64-linux";
        modules = [
          c
        ];
      };
    }
  ) configurations);
  builtNixosMachinesList = builtins.map (m: m.vm-path) builtNixosMachinesListWithNames;
  builtNixosMachinesListWithNames = builtins.map (m: {
    name = m.name;
    vm-path = m.system.config.system.build.vm;
  }) nixosMachines;

  # This generate configurations (for debugging, they aren't needed)
  outputConfigFiles = pkgs.stdenv.mkDerivation {
    name = "generated-vm-configurations";
    phases = [ "installPhase" ];
    installPhase = ''
        mkdir -p $out
      ${builtins.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs (vm-config-name: vm-config: ''
          echo '${pkgs.lib.generators.toPretty {} vm-config}' > $out/configuration-${vm-config-name}.nix
        '') configurations
        ))}
    '';
  };
in
  # Run this generator only once and then have everything in the derivation output
  pkgs.symlinkJoin {
    # this'll be name of the output in the nix store
    name = "testnet-vms";
    # TODO: result/system je u outputu, ali samo za jedan machine jer se overwriteaju
    paths = runVmScriptPaths ++ [ runAllVmsScript outputConfigFiles ] ++ builtNixosMachinesList;
  }
