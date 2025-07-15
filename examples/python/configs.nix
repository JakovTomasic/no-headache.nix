
# todo
# - fix-python (this is the recommended way)
# - fhs devenv

{ pkgs, ... }:
let
  # Change when you generate another ssh key (or add new keys).
  sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs";
in
{
  python-with-nix = {
    init.script = ''
      python /etc/code.py
    '';
    nixos-config = {
      # Copy the script into /etc/code.py
      environment.etc."code.py".source = ./code.py;

      # See shared directory example for more details
      virtualisation.sharedDirectories = {
        exampleSharedDir = {
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/python-with-nix
          source = "/tmp/my-nixos-vms-shared/python-with-nix";
          # Absolute path to virtual machine path
          target = "/mnt/shared";
        };
      };

      environment.systemPackages = with pkgs; [
        # Install python with all needed libraries, directly throught nix
        (python3.withPackages (python-pkgs: with python-pkgs; [
          # add all Python packages here (names might differ from pip, search on https://search.nixos.org/packages?channel=unstable&size=50&sort=relevance&type=packages&query=numpy)
          # also, less popular packages might not be available
          numpy
          pandas
        ]))
      ];

      users.users.nixy.openssh.authorizedKeys.keys = [ sshKey ];
    };
  };
}

