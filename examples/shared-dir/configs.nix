{ pkgs, ... }:
let
in
{
  shared-dirs = {
    init.script = ''
      echo "this is a shared file. This was generated inside the VM." > /mnt/shared/generated-from-vm
    '';
    nixos-config = {

      # Shared directory - the contents of this directory are permanent and will remain on the host OS even after shutting down the VM
      virtualisation.sharedDirectories = {
        # Any name. Multiple shared directories can be here.
        exampleSharedDir = {
          # Absolute path to host OS path of dir to be shared
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/shared-dir-example
          source = "/tmp/my-nixos-vms-shared/shared-dir-example";
          # Absolute path to virtual machine path
          target = "/mnt/shared";
        };
      };

      # Change when you generate another ssh key (or add new keys).
      users.users.nixy.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
      ];
    };
  };
}

