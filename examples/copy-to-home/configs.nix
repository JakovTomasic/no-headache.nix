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
  };
}

