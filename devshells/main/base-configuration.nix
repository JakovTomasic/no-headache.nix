
# This file contains default values. They should all have lib.mkDefault to allow overwrites (don't add lib.mkDefault for types that can be joined automatically, like lists)

# config type is defined in options.nix. It has all the option values
{ pkgs, config }:
let
  lib = pkgs.lib;
  userPkgs = let
      c = config.nixos-config;
      env = if c ? environment then c.environment else {};
      sysPkgs = if env ? systemPackages then env.systemPackages else [];
    in sysPkgs;
  tailscaleEnabled = config.tailscaleAuthKeyFile != null;
  vmEnvVariables = {
    VM_NAME = config.configName;
    VM_INDEX = builtins.toString config.internal.index;
    VM_BASE_NAME = config.internal.baseConfigName;
  };
in
{
  # TODO: pin version
  imports = [ config.nixos-config <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>];

  # Basic system settings
  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Minimal set of packages
  environment.systemPackages = userPkgs ++ (with pkgs; [ vim htop openssh ]);

  # Enable a systemd service to run a script (provided by machine config)
  systemd.services.script-at-boot = let
    tailscaleServiceOrNot = if tailscaleEnabled then [ "tailscaled.service" ] else [];
    tailscaleOrNot = if tailscaleEnabled then [ pkgs.tailscale ] else [];
    homeDir = "/home/${config.username}";
    logFile = "${homeDir}/script-at-boot.log";
    tailscaleSetupScript = ''
      echo "Setting up tailscale" &>> ${logFile}
      tailscaled -state=mem: &>> ${logFile} || true
    '';
    initScriptPath = pkgs.writeScript "init-script.sh" config.init.script;
  in {
    enable = true;
    script = ''
      # Make tailscale ephemeral
      ${if tailscaleEnabled then tailscaleSetupScript else ""}

      echo "Setup done. Starting config.init.script" &>> ${logFile}
      source ${initScriptPath}
    '';
      # ${config.init.script} # TODO: remove

    serviceConfig = {
      Type = "oneshot";               # Runs once and exits
      RemainAfterExit = false;        # Consider service active after it runs
      User = "${config.username}";
      WorkingDirectory = homeDir;     # Optional default directory
      Environment = "HOME=${homeDir}";      # Needed for pip/venv
      # StandardOutput = "journal+console"; # Useful for debugging
      # StandardError = "journal+console";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" "network-online.target" ] ++ tailscaleServiceOrNot;
    requires = [ "local-fs.target" "network-online.target" ] ++ tailscaleServiceOrNot;

    # Manually add all binary files to path (otherwise no program will be available in the path)
    # TODO: can I remove iproute2 and coreutils?
    path = userPkgs ++ tailscaleOrNot ++ (with pkgs; [ iproute2 coreutils ]);

    # Needs to be included separately because global env variables aren't initialized yet
    environment = vmEnvVariables;

    preStart = if config.tailscaleAuthKeyFile == null then "" else ''
        echo "" > ${logFile}
        echo "Waiting for Tailscale IP..." &>> ${logFile}
        while ! ${pkgs.tailscale}/bin/tailscale ip --4 | grep -qE '^100\.'; do
          sleep 1
          echo "Still waiting... Output:" &>> ${logFile}
          ${pkgs.tailscale}/bin/tailscale ip --4 &>> ${logFile}
        done
        echo "Tailscale is ready with IP: $(${pkgs.tailscale}/bin/tailscale ip)" &>> ${logFile}
        '';
  };


  # Enable networking
  networking.useDHCP = lib.mkDefault true;

  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
      enable = lib.mkDefault true;
    };
    hostName = lib.mkDefault config.configName;
  };

  # Enable OpenSSH server
  services.openssh.enable = lib.mkDefault true;
  # services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
  # services.openssh.settings.PasswordAuthentication = lib.mkDefault true;

  services.tailscale = {
    enable = lib.mkDefault tailscaleEnabled;
    # autostart tailscale (even before login to nixos)
    authKeyFile = lib.mkDefault config.tailscaleAuthKeyFile;
    extraUpFlags = [
      # "--login-server" "http://<HOST-IP>:8080"
    ];
  };

  users.users."${config.username}" = {
    isNormalUser = lib.mkDefault true;
    initialPassword = lib.mkDefault "nixos";
    extraGroups = [ "wheel" ];
  };

  # Resource limits for VM (used by qemu-vm module)
  virtualisation.memorySize = lib.mkDefault 1024;   # 1 GB RAM
  virtualisation.cores = lib.mkDefault 1;           # 1 CPU core

  # If host ssh port is defined, setup port forwarding so you can SSH into the VM from your host without VPN.
  virtualisation.forwardPorts = if config.internal.hostSshPort == null then [] else [
    {
      from = "host";
      host.port = config.internal.hostSshPort;
      guest.port = 22;
    }
  ];

  # TODO: Use lib.mkMerge in configs.nix, too
  environment.variables = lib.mkMerge [
    # Only define your new vars here
    vmEnvVariables
  ];

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Optional: enable qemu-guest-agent
  services.qemuGuest.enable = lib.mkDefault true;

  system.stateVersion = lib.mkDefault "24.05"; # Adjust to match your nixpkgs version
}
