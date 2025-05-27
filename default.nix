# TODO: refactor this mess a bit
let
  pkgs = import <nixpkgs> {};
  configBuilder = vm-config: {

    # TODO: maybe make this default config and import it into the nixos-config? (which one has precedence here?)
    # TODO: pin version
    imports = [ vm-config.nixos-config <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>];

    # Basic system settings
    boot.loader.grub.device = "/dev/vda";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Minimal set of packages
    environment.systemPackages = with pkgs; [ vim htop openssh python3 ];


    # Enable a systemd service to run a script (provided by machine config)
    # TODO: ovo treba biti configurable - startup script... ???
    systemd.services.python-app = {
      enable = true;
      # script = ''${vm-config.custom.pythonScript}'';
      script = ''
          # TODO: remove these debug strings
          touch /home/nixy/systemdRadi
          touch /etc/systemdRadi
          tailscale ip -4 server > /home/nixy/tsip
          ${pkgs.python3}/bin/python ${vm-config.custom.pythonScript}
      '';
      # serviceConfig = {
      #   ExecStart = "${pkgs.python3}/bin/python ${vm-config.custom.pythonScript}";
      #   Restart = "always";
      # };
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      requires = [ "network-online.target" "tailscaled.service" ];

      path = with pkgs; [ iproute2 tailscale coreutils ];  # <- makes tailscale, ip, etc. available

      preStart = ''
          echo "Waiting for Tailscale IP..."
          while ! tailscale ip --4 | grep -qE '^100\.'; do
          sleep 1
          done
          echo "Tailscale is ready with IP: $(tailscale ip)"
          '';
    };


    # Enable networking
    networking.useDHCP = true;

    networking = {
      firewall = {
        # TODO: 5000 je potrebno za server.py
        allowedTCPPorts = [ 22 5000 ]; # TODO: ++ ports to open
        allowedUDPPorts = [ 5000 ]; # TODO: ++ ports to open
        enable = true;
      };
      hostName = vm-config.custom.hostName;
    };

    # Enable OpenSSH server
    services.openssh.enable = true;
    # services.openssh.settings.PermitRootLogin = "yes";
    # services.openssh.settings.PasswordAuthentication = true;

    # TODO: move to secrets file?
    users.users.nixy.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
    ];

    services.tailscale = {
      enable = true;
      # autostart tailscale (even before login to nixos)
      authKeyFile = ./secrets/tailscale.authkey;
      extraUpFlags = [
        # "--login-server" "http://<HOST-IP>:8080"
      ];
    };

    # Set nixy password (plaintext; for testing only)
    # TODO: make username configurable (and the password)
    users.users.nixy.isNormalUser = true;
    users.users.nixy.initialPassword = "nixos";
    users.users.nixy.extraGroups = [ "wheel" ];


    # Resource limits for VM (used by qemu-vm module)
    # TODO: uncomment
    virtualisation.memorySize = 1024;   # 1 GB RAM
    virtualisation.cores = 1;           # 1 CPU core

    # # This explicitly tells QEMU to forward localhost:10022 on the host to port 22 inside the guest VM
    # virtualisation.qemu.options = [
    #   "-nic" "user,hostfwd=tcp::10022-:22"
    # ];

    # Optional: enable qemu-guest-agent
    services.qemuGuest.enable = true;

    system.stateVersion = "24.05"; # Adjust to match your nixpkgs version
    # };

  };
  # bigConfig = configBuilder result;
  configs = import ./configs.nix {};
  # TODO: spoji ovo sa nixosMachines - jako slicno. Ovo mozda nije potrebno
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
  # allConfigs = builtins.mapAttrs (vm-config-name: vm-config: {
  #   name = vm-config-name;
  #   value = configBuilder vm-config;
  # }) configurations;
  # TODO: generate build/startup script


  # # TODO: only one derivation - put map inside it? But then I won't have links to the scripts so nvm? - I'll have link to the dir where all scripts are!
  # scripts = builtins.mapAttrs (name: value:
  #   # pkgs.writeShellScriptBin "${name}" ''
  #   #   # TODO: you can use $out in pkgs.stdenv.mkDerivation - actually, no because that's the bottom path, not the root path of the symlink derivation. Or not... Update: yes it's a problem
  #   #   echo "Hello from Nix! ${name} --- $out/" # update - not like this! I already built the nixosMachines. Just run them
  #   #   # rm -f ${name}.qcow2
  #   #   # nix run nixpkgs#nixos-rebuild -- build-vm -I nixos-config=./client.nix
  #   #   # rm -rf result-client
  #   #   # mv result result-client
  #   #   ''
  #   pkgs.stdenv.mkDerivation {
  #     name = "run-vm-${name}";
  #     phases = [ "installPhase" ];
  #     installPhase = ''
  #       mkdir -p $out
  #       echo 'mkdir -p $out' >> script-${name}.sh
  #       echo 'echo "ls $out"'  >> script-${name}.sh
  #       echo 'ls $out'  >> script-${name}.sh
  #       echo 'echo "ls $out/bin"'  >> script-${name}.sh
  #       echo 'ls $out/bin'  >> script-${name}.sh
  #       echo 'echo "ls $out/bin/run-${name}-vm"'  >> script-${name}.sh
  #       echo '$out/bin/run-${name}-vm'  >> script-${name}.sh
  #     '';
  #   }
  # ) configs;
  # TODO: this above or alternative below:
  scripts = pkgs.lib.foldl' pkgs.lib.mergeAttrs {} (builtins.map (machine:
    {
      "${machine.name}" = pkgs.writeShellScriptBin "${machine.name}" ''
        echo "Running ${machine.name}"
        # TODO: run in background, don't block execution - provide options for that (as parameters to this script?)
        ${machine.vm-path}/bin/run-${machine.name}-vm &
      '';
    }
  ) builtNixosMachinesListWithNames);



  scriptPaths = builtins.attrValues scripts;
  runAllScripts = pkgs.writeShellScriptBin "build" ''
    pwd
    ${builtins.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs (name: value: "${value}/bin/${name}") scripts)
    )}
  '';

  # TODO: pin version
  nixosSystem = import <nixpkgs/nixos/lib/eval-config.nix>;
  nixosMachines = builtins.mapAttrs (name: c:
    {
      name = name;
      system = nixosSystem {
        system = "x86_64-linux";
        modules = [
          c
        ];
      };
    }
  ) configurations;
  builtNixosMachinesList = builtins.map (m: m.system.config.system.build.vm) (builtins.attrValues nixosMachines);
  builtNixosMachinesListWithNames = builtins.map (m: {
    name = m.name;
    vm-path = m.system.config.system.build.vm;
  }) (builtins.attrValues nixosMachines);

  # Run this generator only once and then have everything in the derivation output
  # This generate configurations (for debugging, they're not needed)
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

pkgs.symlinkJoin {
  # this'll be name of the output in the nix store
  name = "testnet-vms";
  # TODO: result/system je u outputu, ali samo za jedan machine jer se overwriteaju
  paths = scriptPaths ++ [ runAllScripts outputConfigFiles ] ++ builtNixosMachinesList;
}

# TODO: use, document, and/or remove this
# - potential problem: the output config path will differ so file paths may be invalid?
#   - nope! It converts them to apsolute paths
# - it may be good idea to run this generator oncy once and then have everything in the derivation output
# generate configuration.nix file
# pkgs.writeText "output-configuration.nix" (pkgs.lib.generators.toPretty {} configurations)

# TODO: use, document, and/or remove this
# generate configuration.nix file
# let
#   pretty = pkgs.lib.generators.toPretty {} configurations;
#   mkDer = pkgs.stdenv.mkDerivation {
#     name = "configuration-nix";
#     phases = [ "installPhase" ];
#     installPhase = ''
#       mkdir -p $out
#       echo '${pretty}' > $out/output-configuration.nix
#     '';
#   };
# in
# mkDer


