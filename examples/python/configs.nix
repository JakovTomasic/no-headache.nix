{ pkgs, ... }:
let
  # Change when you generate another ssh key (or add new keys).
  sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs";
in
{
  # Example of a problem with python code and why solutions below are necessary.
  python-error = {
    init.script = ''
      # this doesn't work because required libraries aren't installed
      # TODO: output error to shared dir OR print journalctl?
      python /etc/code.py
    '';
    firstHostSshPort = 2100;
    nixos-config = {
      # Copy the script into /etc/code.py
      environment.etc."code.py".source = ./code.py;

      environment.systemPackages = with pkgs; [ python3 ];

      users.users.nixy.openssh.authorizedKeys.keys = [ sshKey ];
    };
  };

  # If you can avoid using requirements.txt and/or have few dependencies which are popular libraries you can use this native Nix approach.
  # This has the fastest build as it doesn't have to install packages from pip every time.
  python-native-nix = {
    init.script = ''
      python /etc/code.py
    '';
    firstHostSshPort = 2200;
    nixos-config = {
      # Copy the script into /etc/code.py
      environment.etc."code.py".source = ./code.py;

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
      # TODO: this is temporary. Remove it
      # TODO: explain somewhere that this files copied to home (etc but thats hidden from the user?) are immutable and to create mutable copy just run cp code.py code2.py where code2.py is now a mutable copy.
      cp -P /etc/code.py ~/code.py
      cp -P /etc/requirements.txt ~/requirements.txt

      # Note: initialization may take few dozen seconds. Check shared status.txt to validate intialization is running.
      echo "venv init start" > /mnt/shared/status.txt
      python-fhs -c 'init-python-venv -r requirements.txt'
      echo "venv init done. Starting the script." >> /mnt/shared/status.txt
      python-fhs -c 'source venv/bin/activate && python code.py'
    '';
    firstHostSshPort = 2300;
    nixos-config = {
      # Copy the script and requirements into VM directory /etc
      environment.etc."code.py".source = ./code.py;
      environment.etc."requirements.txt".source = ./requirements.txt;

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

  # TODO: fhs-env with shared venv dir (recommended???) - init venv in shared dir so its persistant and reinit takes less time. Also document that
}

