# config type is defined in options.nix. It has all the option values
{ pkgs, config }:
{
  # TODO: maybe make this default config and import it into the nixos-config? (which one has precedence here?)
  # TODO: pin version
  imports = [ config.nixos-config <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>];

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
    # script = ''${config.custom.pythonScript}'';
    script = ''
        # TODO: remove these debug strings
        touch /home/nixy/systemdRadi
        touch /etc/systemdRadi
        tailscale ip -4 server > /home/nixy/tsip
        ${pkgs.python3}/bin/python ${config.custom.pythonScript}
    '';
    # serviceConfig = {
    #   ExecStart = "${pkgs.python3}/bin/python ${config.custom.pythonScript}";
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
    hostName = config.custom.hostName;
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
}
