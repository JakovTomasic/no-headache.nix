{ userConfigsFile }:
let
  # TODO: somehow pass pkgs into here? Run this from flake.nix?
  pkgs = import <nixpkgs> {};
  configBuilder = config: (import ./base-configuration.nix { inherit pkgs config; });

  userConfigs = import userConfigsFile { inherit pkgs; };
  # Generates nix configurations (effectively configuration.nix files)
  configurations = builtins.concatLists (builtins.attrValues (builtins.mapAttrs (name: value:
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
                internal.hostSshPort = if value ? firstHostSshPort && value.firstHostSshPort != null then value.firstHostSshPort + i else null;
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
        pureConfig = c.value; # Original user config, with added internal values
    }) configsReadyForBuilder
  ) userConfigs));


  # Scripts that run generated VMs
  runVmScripts = pkgs.lib.foldl' pkgs.lib.mergeAttrs {} (builtins.map (machine:
    {
      "${machine.name}" = pkgs.writeShellScriptBin "${machine.name}" ''
        if [[ -e "${machine.name}.qcow2" ]]; then
          echo "Warning: using cached image '${machine.name}.qcow2'. Delete it if you've rebuilt VM." >&2
        fi
        echo "Running ${machine.name}"
        # TODO: run in background, don't block execution - provide options for that (as parameters to this script?)
        ${machine.vm-path}/bin/run-${machine.name}-vm $@ &
      '';
    }
  ) builtNixosMachinesListWithNames);
  runVmScriptPaths = builtins.attrValues runVmScripts;

  # A script that runs all VMs at the same time
  runAllVmsScript = pkgs.writeShellScriptBin "runAll" ''
    ${builtins.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs (name: value: "${value}/bin/${name} $@") runVmScripts)
    )}
  '';

  # SSH into a VM from the host
  sshIntoVmScripts = pkgs.lib.foldl' pkgs.lib.mergeAttrs {} (builtins.map (c:
    let scriptName = "ssh-into-${c.pureConfig.configName}"; in
    {
      "${scriptName}" = pkgs.writeShellScriptBin "${scriptName}" ''
        if ${if c.pureConfig.firstHostSshPort == null then "true" else "false"}; then
          echo "Error! VM ${c.pureConfig.configName} doesn't have SSH from host enabled. Please set firstHostSshPort option in your configs file."
        else
          # Don't save the VM to user known hosts because when running other VM on the same port it'll throw an error that the VM is different and you'd have to remove it from known hosts file.
          echo "running: ssh -p ${builtins.toString c.pureConfig.internal.hostSshPort} \"${c.pureConfig.username}@localhost\" -o \"UserKnownHostsFile=/dev/null\""
          ssh -p ${builtins.toString c.pureConfig.internal.hostSshPort} "${c.pureConfig.username}@localhost" -o "UserKnownHostsFile=/dev/null"
        fi
      '';
    }
  ) configurations);
  sshIntoVmScriptPaths = builtins.attrValues sshIntoVmScripts;


  # Generate nixos virtual machines (effectively the same as running nixos-rebuild -- build-vm)
  # TODO: pin version - there is a specific way how to do this with flakes?
  nixosSystem = import <nixpkgs/nixos/lib/eval-config.nix>;
  nixosMachines = builtins.map (c:
    {
      name = c.name;
      system = nixosSystem {
        system = "x86_64-linux";
        modules = [
          c.value
        ];
      };
    }
  ) configurations;
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
        builtins.map (vm-config: ''
          echo '${pkgs.lib.generators.toPretty {} vm-config.value}' > $out/configuration-${vm-config.name}.nix
        '') configurations
      )}
    '';
  };

  # Run this generator only once and then have everything in the derivation output
  rootResultDerivation = pkgs.symlinkJoin {
    # this'll be name of the output in the nix store
    name = "testnet-vms";
    # TODO: result/system je u outputu, ali samo za jedan machine jer se overwriteaju
    paths = runVmScriptPaths ++ [ runAllVmsScript outputConfigFiles ] ++ sshIntoVmScriptPaths ++ builtNixosMachinesList;
  };
in
  rootResultDerivation
