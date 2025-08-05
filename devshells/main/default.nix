{ userConfigsFile, generateDiskImages, system }:
let
  # Flake version will be used because NIX_PATH is overwritten
  pkgs = import <nixpkgs> { inherit system; };

  lib = pkgs.lib;
  configBuilder = { config, forDiskImage }: (import ./base-configuration.nix { inherit pkgs config forDiskImage; });
  # Helper function
  mapIfNotNull = f: list:
    builtins.filter (x: x != null) (map f list);


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
          value = (lib.evalModules {
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
        pureConfig = c.value; # Original user config, with added internal values
        vmConfig = configBuilder { config = c.value; forDiskImage = false; };
        diskImageConfig = configBuilder { config = c.value; forDiskImage = true; };
    }) configsReadyForBuilder
  ) userConfigs));


  # Scripts that run generated VMs
  runVmScripts = lib.foldl' lib.mergeAttrs {} (builtins.map (machine:
    {
      "${machine.name}" = pkgs.writeShellScriptBin "${machine.name}" ''
        if [[ -e "${machine.name}.qcow2" ]]; then
          echo "Warning: using cached image '${machine.name}.qcow2'. Delete it if you've rebuilt VM." >&2
        fi

        # default values
        MODE_NAME="window mode"
        VM_ARG=""
        BACKGROUND="true"

        # Take just the first option
        case "$1" in
          -n|--noui)
            MODE_NAME="noui mode"
            VM_ARG="-display none"
            BACKGROUND="true"
            shift 1
          ;;
          -w|--window)
            # default values already set
            shift 1
          ;;
          *)
            # use default values
            # Don't shift arguments because no custom arguemnt was provided - don't mess up qemu arguments
          ;;
        esac

        echo "Running ${machine.name} in $MODE_NAME"
        # Pass all other arguments to the qemu
        if [ "$BACKGROUND" = "true" ]; then
          ${machine.vm-path}/bin/run-${machine.name}-vm $VM_ARG $@ &
        else
          ${machine.vm-path}/bin/run-${machine.name}-vm $VM_ARG $@
        fi
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
  sshIntoVmScripts = lib.foldl' lib.mergeAttrs {} (builtins.map (c:
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


  # Generate nixos machines (effectively the same as running nixos-rebuild -- build-vm)
  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";
  nixosMachines = builtins.map (c:
    let
      # Only one image is built per configuration - ignoring count option
      makeDisk = c.pureConfig.diskImage != null && generateDiskImages && c.pureConfig.internal.index == 1;
      diskImageSystem = if !makeDisk then null else nixosSystem {
        system = system;
        modules = [
          c.diskImageConfig
        ];
      };
    in
    {
      name = c.name;
      vmSystem = nixosSystem {
        system = system;
        modules = [
          c.vmConfig
        ];
      };
      diskImageSystem = diskImageSystem;
      pureConfig = c.pureConfig;
    }
  ) configurations;
  builtNixosMachinesListWithNames = builtins.map (m: {
    name = m.name;
    vm-path = m.vmSystem.config.system.build.vm;
  }) nixosMachines;
  builtNixosMachinesList = builtins.map (m: m.vm-path) builtNixosMachinesListWithNames;

  # This generate configurations (for debugging, they aren't needed)
  outputConfigFiles = pkgs.stdenv.mkDerivation {
    name = "generated-vm-configurations";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      ${builtins.concatStringsSep "\n" (
        builtins.map (vm-config: ''
          echo '${lib.generators.toPretty {} vm-config.vmConfig}' > $out/configuration-${vm-config.name}.nix
        '') configurations
      )}
    '';
  };

  make-disk-image = import "${pkgs.path}/nixos/lib/make-disk-image.nix";
  qcow2Images = if !generateDiskImages then [] else mapIfNotNull (m:
    let
      configName = m.pureConfig.internal.baseConfigName;
      gen-image = {}: make-disk-image ({
        inherit pkgs lib;
        config = m.diskImageSystem.config;
        name = configName;
        baseName = configName;
        partitionTableType = "legacy+gpt";
        installBootLoader = true;
        onlyNixStore = false;
        touchEFIVars = true;
      } // m.pureConfig.diskImage);
    in
      if m.diskImageSystem != null then gen-image {} else null
  ) nixosMachines;

  # Run this generator only once and then have everything in the derivation output
  rootResultDerivation = pkgs.symlinkJoin {
    # this'll be name of the output in the nix store
    name = "lessheadache";
    paths = runVmScriptPaths ++ [ runAllVmsScript outputConfigFiles ] ++ sshIntoVmScriptPaths ++ builtNixosMachinesList ++ qcow2Images;
  };
in
  rootResultDerivation
