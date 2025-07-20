{ pkgs, ... }:
let
  # Change when you generate another ssh key (or add new keys).
  sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs";
in
{
  # Example of a problem with python code and why solutions below are necessary.
  python-error = {
    init.script = ''
      # This doesn't work because required libraries aren't installed
      # Run it in the VM manually to see the errors.
      python ~/code.py
    '';
    copyToHome = {
      # Copy the script into /home/nixy/code.py
      "code.py" = ./code.py;
    };
    firstHostSshPort = 2100;
    nixos-config = {
      environment.systemPackages = with pkgs; [ python3 ];

      users.users.nixy.openssh.authorizedKeys.keys = [ sshKey ];
    };
  };

  # If you can avoid using requirements.txt and/or have few dependencies which are popular libraries you can use this native Nix approach.
  # This has the fastest build as it doesn't have to install packages from pip every time.
  python-native-nix = {
    init.script = ''
      python ~/code.py
    '';
    firstHostSshPort = 2200;
    copyToHome = {
      # Copy the script into /home/nixy/code.py
      "code.py" = ./code.py;
    };
    nixos-config = {
      # See shared directory example for more details
      virtualisation.sharedDirectories = {
        exampleSharedDir = {
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/python-native-nix
          source = "/tmp/my-nixos-vms-shared/python-native-nix";
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

  # If you have requirements.txt and don't want to mess around with nix packages this is the simplest solution to run python.
  # The initialization is a bit slower
  python-fhs-env = {
    init.script = ''
      # Note: initialization may take few minutes. Check shared status.txt to validate intialization is running.
      # You can also run 'systemctl status script-at-boot' in the VM to check if this script is still running or if it crashed.
      echo "venv init start" > /mnt/shared/status.txt
      python-fhs -c 'init-python-venv -r requirements.txt'
      echo "venv init done. Starting the script." >> /mnt/shared/status.txt
      python-fhs -c 'source venv/bin/activate && python code.py'
    '';
    copyToHome = {
      # Copy the script and requirements into VM home directory
      "code.py" = ./code.py;
      "requirements.txt" = ./requirements.txt;
    };
    firstHostSshPort = 2300;
    nixos-config = {
      # See shared directory example for more details
      virtualisation.sharedDirectories = {
        exampleSharedDir = {
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/python-fhs-env
          source = "/tmp/my-nixos-vms-shared/python-fhs-env";
          # Absolute path to virtual machine path
          target = "/mnt/shared";
        };
      };

      environment.systemPackages = with pkgs; [
        # Adding python FHS environment for pip install support.
        # See 'Python-FHS compat env' in README.md
        (import ../../compat-envs/python-fhs.nix { inherit pkgs; })
      ];

      users.users.nixy.openssh.authorizedKeys.keys = [ sshKey ];
    };
  };

  # Like python-fhs-env, but uses persistent shared directory for the venv.
  # Useful when rebuilding VMs and resetting all VM storage as venv setup and package installation can take a long time.
  # This is a recommended approach if you expect VM config changes and reseting it's storage, especially in developing configs.nix.
  python-shared-venv = {
    init.script = ''
      # The main difference from other fhs solution: create venv in the shared dir
      cd /mnt/shared/

      # Note: initialization may take few minutes (only the first time for the shared venv approach). Check shared status.txt to validate intialization is running.
      # You can also run 'systemctl status script-at-boot' in the VM to check if this script is still running or if it crashed.
      echo "venv init start" > status.txt
      python-fhs -c 'init-python-venv -r ~/requirements.txt'
      echo "venv init done. Starting the script." >> status.txt
      python-fhs -c 'source venv/bin/activate && python ~/code.py'
    '';
    copyToHome = {
      # Copy the script and requirements into VM home directory
      "code.py" = ./code.py;
      "requirements.txt" = ./requirements.txt;
    };
    firstHostSshPort = 2400;
    nixos-config = {
      # See shared directory example for more details
      virtualisation.sharedDirectories = {
        exampleSharedDir = {
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/python-shared-venv
          source = "/tmp/my-nixos-vms-shared/python-shared-venv";
          # Absolute path to virtual machine path
          target = "/mnt/shared";
        };
      };

      environment.systemPackages = with pkgs; [
        # Adding python FHS environment for pip install support.
        # See 'Python-FHS compat env' in README.md
        (import ../../compat-envs/python-fhs.nix { inherit pkgs; })
      ];

      users.users.nixy.openssh.authorizedKeys.keys = [ sshKey ];
    };
  };
}

