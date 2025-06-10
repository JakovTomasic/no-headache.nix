{ userConfigsFile }:
let
  pkgs = import <nixpkgs> {};
  configBuilder = config: (import ./base-configuration.nix { inherit pkgs config; });

  userConfigs = import userConfigsFile { inherit pkgs; };
  # Generates nix configurations (effectively configuration.nix files)
  configurations = builtins.listToAttrs (builtins.concatLists (builtins.attrValues (builtins.mapAttrs (name: value:
    let
      count = (value.count or 1);
      configsReadyForBuilder = builtins.genList (i: 
        let
          configName = if count == 1 then name else "${name}-${builtins.toString (i+1)}";
        in
        {
          # Keep name to pass-on later. Otherwise this info will be lost.
          name = configName;
          # Build module to be passed into configBuilder
          value = (pkgs.lib.evalModules {
            modules = [
              ./options.nix
              value
              {
                configName = configName;
                internal.baseConfigName = name;
                internal.index = i+1;
              }
            ];
          }).config;
        }
      ) count;
    in
    # listToAttrs will convert list of name-value attrs to attr {name1 = value1, name2 = value2, ...}
    builtins.map (c: {
        name = c.name;
        value = configBuilder c.value;
    }) configsReadyForBuilder
  ) userConfigs)));


  # Scripts that run generated VMs
  runVmScripts = pkgs.lib.foldl' pkgs.lib.mergeAttrs {} (builtins.map (machine:
    {
      "${machine.name}" = pkgs.writeShellScriptBin "${machine.name}" ''
        if [[ -e "${machine.name}.qcow2" ]]; then
          echo "Warning: using cached image '${machine.name}.qcow2'. Delete it if you've rebuilt VM." >&2
        fi
        echo "Running ${machine.name}"
        # TODO: run in background, don't block execution - provide options for that (as parameters to this script?)
        ${machine.vm-path}/bin/run-${machine.name}-vm &
      '';
    }
  ) builtNixosMachinesListWithNames);
  runVmScriptPaths = builtins.attrValues runVmScripts;

  # A script that runs all VMs at the same time
  runAllVmsScript = pkgs.writeShellScriptBin "runAll" ''
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
