
# This file contains default values. They should all have lib.mkDefault to allow overwrites (don't add lib.mkDefault for types that can be joined automatically, like lists)

# config type is defined in options.nix. It has all the option values
# if forDiskImage is true the configuration is for full disk image. Otherwise it's for VM.
{ pkgs, config, forDiskImage }:
let
  lib = pkgs.lib;

  virtConfigOrNot = if forDiskImage then {} else config.nixos-config-virt;

  userPkgs = let
      base = config.nixos-config;
      baseEnv = if base ? environment then base.environment else {};
      baseSysPkgs = if baseEnv ? systemPackages then baseEnv.systemPackages else [];
      vm = virtConfigOrNot;
      vmEnv = if vm ? environment then vm.environment else {};
      vmSysPkgs = if vmEnv ? systemPackages then vmEnv.systemPackages else [];
    in baseSysPkgs ++ vmSysPkgs;
  tailscaleEnabled = config.tailscaleAuthKeyFile != null;
  # Disk image name shouldn't have -index suffix because they ignore count
  configName = if forDiskImage then config.internal.baseConfigName else config.configName;
  envVariables = {
    MACHINE_NAME = configName;
    MACHINE_INDEX = builtins.toString config.internal.index;
    MACHINE_BASE_NAME = config.internal.baseConfigName;
    MACHINE_TYPE = if forDiskImage then "image" else "virtual";
  };
  copyToHomeTmpEtcDirName = "copied-from-host-for-home-dir";

  # If the worng one is included the boot image won't be able to mount
  qemuImport = if forDiskImage then
    "${pkgs.path}/nixos/modules/profiles/qemu-guest.nix" # required for running full disk image with qemu
  else
    "${pkgs.path}/nixos/modules/virtualisation/qemu-vm.nix";

  # Virtualisation options don't work in disk images and build error will be thrown if they're defined
  virtualisationOptions = if forDiskImage then {} else {
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
  };
in
{
  imports = [
    config.nixos-config
    virtConfigOrNot
    qemuImport
    virtualisationOptions
  ];

  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  # Required for disk image:
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Don't show configuration selector. Just boot into the only configuration.
  boot.loader.timeout = lib.mkDefault 0;

  environment = {
    # Minimal set of packages
    systemPackages = userPkgs ++ (with pkgs; [ vim htop openssh ]);

    variables = envVariables;

    etc = let
      # Copy to home doesn't exist so I'll use environment.<name>.source to copy it to env and then I'll copy that symlink from env to home in the init script.
      copyToEnv = lib.attrValues (lib.mapAttrs (destPath: srcPath:
        { "${copyToHomeTmpEtcDirName}/${destPath}".source = srcPath; }
      ) config.copyToHome);
    in lib.mkMerge copyToEnv;
  };


  # Enable a systemd service to run a script (provided by machine config)
  systemd.services.script-at-boot = let
    tailscaleServiceOrNot = if tailscaleEnabled then [ "tailscaled.service" ] else [];
    tailscaleOrNot = if tailscaleEnabled then [ pkgs.tailscale ] else [];
    homeDir = "/home/${config.username}";
    logFile = "'${homeDir}/script-at-boot.log'";
    initScriptPath = pkgs.writeShellScriptBin "init-script.sh" config.init.script;
    serviceScript = pkgs.writeShellScriptBin "serviceScript.sh" ''
      echo "" > ${logFile}
      echo "Starting boot service..." &>> ${logFile}

      # Copy all symlinks from temporary etc dir to desired home destinations. (run as user)
      runuser -l ${config.username} -c 'cp -Pr /etc/${copyToHomeTmpEtcDirName}/* ~'

      echo "Setup done. Starting config.init.script" &>> ${logFile}
      # Run the init script as user
      runuser -l ${config.username} -c "${initScriptPath}/bin/init-script.sh"
    '';
  in {
    enable = true;
    # Run the script as root and then switch to the user for user-defined script.
    script = "${serviceScript}/bin/serviceScript.sh";

    serviceConfig = {
      Type = "oneshot";               # Runs once and exits
      RemainAfterExit = false;        # Consider service active after it runs
      WorkingDirectory = homeDir;     # Optional default directory
      Environment = "HOME=${homeDir}";      # Needed for pip/venv
      # StandardOutput = "journal+console"; # Useful for debugging
      # StandardError = "journal+console";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" "network-online.target" ] ++ tailscaleServiceOrNot;
    requires = [ "local-fs.target" "network-online.target" ] ++ tailscaleServiceOrNot;

    # Manually add all binary files to path (otherwise no program will be available in the path)
    path = userPkgs ++ tailscaleOrNot ++ (with pkgs; [
      util-linux # for the runuser command
    ]);

    # Needs to be included separately because global env variables aren't initialized yet
    environment = envVariables;
  };


  # Enable networking
  networking.useDHCP = lib.mkDefault true;

  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
      enable = lib.mkDefault true;
    };
    hostName = lib.mkDefault configName;
  };

  # Enable OpenSSH server
  services.openssh.enable = lib.mkDefault true;
  # services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
  # services.openssh.settings.PasswordAuthentication = lib.mkDefault true;

  services.tailscale = {
    enable = lib.mkDefault tailscaleEnabled;
    # autostart tailscale (even before login to nixos)
    authKeyFile = lib.mkDefault config.tailscaleAuthKeyFile;
    extraUpFlags = lib.mkDefault [
      # "--login-server" "http://<HOST-IP>:8080"
    ];
  };

  users.users."${config.username}" = {
    isNormalUser = lib.mkDefault true;
    initialPassword = lib.mkDefault "nixos";
    extraGroups = [ "wheel" ];
  };

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
