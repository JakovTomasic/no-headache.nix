{ pkgs, ... }:
let
in
{
  copy-to-home = {
    copyToHome = {
      # Copy file.txt in user home directory
      "file.txt" = ./file.txt;
      # Copy whole directory to the VM home directory, recursively
      "dir" = ./dir;
      # Copy file.txt in user home directory, but change the name and path so it doesn't match with the original file
      "configs/file2/my-file.txt" = ./file2.txt;
      # Copy whole directory to the VM home directory (recursively), but change the name so it doesn't match with the original dir name
      "dir2-renamed" = ./dir2;
    };
    init.script = ''
      # file.txt is write-only so do this if you want to modify it (then modify modifiable-file.txt).
      cp ~/file.txt ~/modifiable-file.txt
    '';
    firstHostSshPort = 2200;
    nixos-config = {
      # Change when you generate another ssh key (or add new keys).
      users.users.nixy.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
      ];
    };
  };
}

