
# This file contains default values. They should all have lib.mkDefault to allow overwrites (don't add lib.mkDefault for types that can be joined automatically, like lists)

# config type is defined in options.nix. It has all the option values
{ pkgs, config }:
let
  lib = pkgs.lib;
  userPkgs = config.nixos-config.environment.systemPackages;
  tailscaleEnabled = config.tailscaleAuthKeyFile != null;
in
{
  # TODO: maybe make this default config and import it into the nixos-config? (which one has precedence here?)
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
  in {
    enable = true;
    script = ''
      # Make tailscale ephemeral
      ${if tailscaleEnabled then "tailscaled -state=mem:" else ""}
      ${config.init.script}
    '';

    # TODO: re-enable this? Make python script that crashes every 5 ticks to test restarting?
    # serviceConfig = {
    #   ExecStart = "${pkgs.python3}/bin/python ${config.custom.pythonScript}";
    #   Restart = "always";
    # };

    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ] ++ tailscaleServiceOrNot;
    requires = [ "network-online.target" ] ++ tailscaleServiceOrNot;

    # Manually add all binary files to path (otherwise no program will be available in the path)
    # TODO: can I remove iproute2 and coreutils?
    path = userPkgs ++ tailscaleOrNot ++ (with pkgs; [ iproute2 coreutils ]);

    preStart = if config.tailscaleAuthKeyFile == null then "" else ''
        echo "Waiting for Tailscale IP..."
        while ! tailscale ip --4 | grep -qE '^100\.'; do
        sleep 1
        done
        echo "Tailscale is ready with IP: $(tailscale ip)"
        '';
  };


  # Enable networking
  networking.useDHCP = lib.mkDefault true;

  networking = {
    firewall = {
      # TODO: 5000 je potrebno za server.py
      allowedTCPPorts = [ 22 5000 ]; # TODO: ++ ports to open
      allowedUDPPorts = [ 5000 ]; # TODO: ++ ports to open
      enable = lib.mkDefault true;
    };
    hostName = lib.mkDefault config.configName;
  };

  # Enable OpenSSH server
  services.openssh.enable = lib.mkDefault true;
  # services.openssh.settings.PermitRootLogin = "yes";
  # services.openssh.settings.PasswordAuthentication = true;

  # # TODO: move to secrets file? (or at least to configs.nix. This mustn't be here)
  # users.users."${config.username}".openssh.authorizedKeys.keys = lib.mkDefault [
  #   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
  # ];

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

  # # This explicitly tells QEMU to forward localhost:10022 on the host to port 22 inside the guest VM
  # virtualisation.qemu.options = [
  #   "-nic" "user,hostfwd=tcp::10022-:22"
  # ];

  # Optional: enable qemu-guest-agent
  services.qemuGuest.enable = lib.mkDefault true;

  system.stateVersion = lib.mkDefault "24.05"; # Adjust to match your nixpkgs version
}
