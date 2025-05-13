{ config, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix> ];

  # Basic system settings
  boot.loader.grub.device = "/dev/vda";
  boot.loader.systemd-boot.enable = true; # TODO: remove?
  boot.loader.efi.canTouchEfiVariables = true; # TODO: remove?


  # Enable networking
  networking.useDHCP = true;

  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
      enable = true;
    };
    hostName = "nixos-vm";
  };

  # Enable OpenSSH server
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;

  users.users.nixy.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
  ];

  # Set nixy password (plaintext; for testing only)
  users.users.nixy.isNormalUser = true; # TODO: remove?
  users.users.nixy.initialPassword = "nixos";
  users.users.nixy.extraGroups = [ "wheel" ];


  # Resource limits for VM (used by qemu-vm module)
  virtualisation.memorySize = 1024;   # 1 GB RAM
  virtualisation.cores = 1;           # 1 CPU core

  # This explicitly tells QEMU to forward localhost:10022 on the host to port 22 inside the guest VM
  virtualisation.qemu.options = [
    "-nic" "user,hostfwd=tcp::10022-:22"
  ];


  # Optional: enable qemu-guest-agent
  services.qemuGuest.enable = true;

  # Minimal set of packages
  environment.systemPackages = with pkgs; [ vim htop openssh ];

  system.stateVersion = "24.05"; # Adjust to match your nixpkgs version
}

