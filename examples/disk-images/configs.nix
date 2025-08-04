{ pkgs, ... }:
let
  vmSshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs";
  diskImageSshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+0geHvKu0jNw/MjM4kUm2S0n7ie9Gh90WTguVmEwHKtKZFaJVmpX+SLLLX5jIUQKOWXMoeLD2y0pTbCRMuElmJW6jolp68crtNRBdLKpCwG2bmgnpVwGRm91QVUEkn2NE5ulb8vgOixHU5tky0rJtwAlAt+JyWD/NGWgy3Dv7pGup4csJ7dDoo7sNzEIQqr5ExjnmJjgQY/MOJyfrUBRsFfecDd/SAe0HIbstx4DMD41k3AfWP71mYSq3NXkbDEkYSlrm0uKnat1TXd6Xa6kbcUQ4oQNQ4mbeTw5eKsRBg+LZEDzsWJJLn0/0VafUtvc1huWfRKlreYlH8VTF4bJlc86Eak8Wqp7yph0cGh2xWEGQ4TETzSkbyNKtJ1JPPKsUak6XAuGtB5HyRrmB6lVSeWMgFtJc+vFUbQ+3tDQtLEH1mfHGAzqD3vtmJCfMN6Mqyhp+zp/+1uQ6r68R4KBDRYLhhQSwxNg1rYVNNgBi7XjzQPEJFYh3wtiEbOornWCVPALEemo0MRe/FxggeXrWGuRAR2fade9gbdu4+obR/aB0DNc067hbQpg8NPNpgeMWoBnAlT3v5fPLxMU4+hbhR2qb0LvHEIGxmOVkjONvymvBnl+AVEGlyGmUVWGl2YDRXht94qO+Xf8zzIhibDsJOjU4VrdyGwkBLfm5G9XKLw== another key";
in
{
  # Reminder: add --images to build command or images won't be built.

  # Create single disk image with defined format
  singleImage = {
    diskImage = {
      # Here, you can define any parameters from https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix

      format = "qcow2";
      additionalSpace = "512M";
    };
    nixos-config = {
      # Install cowsay in every VM and image with this configuration
      environment.systemPackages = with pkgs; [ cowsay ];

      # Default value overwriteen in the nixos-config-virt
      # See active keys by running: cat /etc/ssh/authorized_keys.d/nixy
      users.users.nixy.openssh.authorizedKeys.keys = [ diskImageSshkey ];
    };
    # Disk images won't use options defined in nixos-config-virt, but directly run VMs will.
    nixos-config-virt = {
      # Shared directory and other virtualisation. options must be defined here in nixos-config-virt
      virtualisation.sharedDirectories = {
        exampleSharedDir = {
          # Absolute path to host OS path of dir to be shared
          # Important: you need to create this directory before starting this VM
          # use: mkdir -p /tmp/my-nixos-vms-shared/disk-images-example
          source = "/tmp/my-nixos-vms-shared/disk-images-example";
          # Absolute path to virtual machine path
          target = "/mnt/shared";
        };
      };

      # Install cowsay (defined in nixos-config) but also lolcat - lolcat will be installed only in virtual machine, not in disk image.
      environment.systemPackages = with pkgs; [ lolcat ];

      # Normal nixos option (not virtualisation) can also be added in VM-only config.
      # For example, let's define another environment variable:
      environment.variables = {
        # To check if variable is present fun: echo $MY_ENV_VAR 
        MY_ENV_VAR = "My VM-only custom env variable";
      };

      # Options defined here overwrite options in the nixos-config.
      # Use pkgs.lib.mkForce to overwrite default value (intead of concatinating it)
      # See active keys by running: cat /etc/ssh/authorized_keys.d/nixy
      users.users.nixy.openssh.authorizedKeys.keys = pkgs.lib.mkForce [ vmSshkey ];
    };
  };

  # Only one disk image will be created.
  # When running normally as VM it'll start two VM instances (index 1 and 2, full names twoVmsButSingleImage-1 and twoVmsButSingleImage-2).
  # But when building images it'll create only one image (full name twoVmsButSingleImage)
  twoVmsButSingleImage = {
    count = 2;
    diskImage = {
      # Here, you can define any parameters from https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix

      # Different format than the singleImage
      format = "qcow2-compressed";
      additionalSpace = "0M"; # overwrite the default
    };
    init.script = ''
      # Print properties of this instance to validate that two VMs, but only one image is created.
      echo "$MACHINE_NAME" > ~/machine_name.txt
      # In disk images, index will always be 1
      echo "$MACHINE_INDEX" > ~/machine_index.txt
      echo "$MACHINE_BASE_NAME" > ~/machine_base_name.txt
      # machine type is "image" in disk image and "virtual" for VM
      echo "$MACHINE_TYPE" > ~/machine_type.txt
    '';
    nixos-config = {
      # Install lolcat in every VM and image with this configuration
      environment.systemPackages = with pkgs; [ lolcat ];
    };
    # No nixos-config-virt, it's optional
  };

  # Doesn't have diskImage so image won't be created. But VM will work normally.
  onlyVm = {
    nixos-config = {
      # Install python3 in every VM and image with this configuration
      environment.systemPackages = with pkgs; [ python3 ];
    };
  };

  # Count is 0 so no disk image will be created
  noImage = {
    count = 0;
  };
}
