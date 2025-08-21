{ pkgs, customArgs, ... }:
let
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
    };
  };
}

