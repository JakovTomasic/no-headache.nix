{ pkgs, ... }:
let
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
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ ../sshkeys/another_key.pub ];
    };
    # Disk images won't use options defined in nixos-config-virt, but directly run VMs will.
    nixos-config-virt = {
      # Shared directory and other virtualisation. Options must be defined here in nixos-config-virt
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

      # Use pkgs.lib.mkForce to overwrite default value (intead of concatinating it)
      # See active keys by running: cat /etc/ssh/authorized_keys.d/nixy
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ ../sshkeys/example_ssh_key.pub ];
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
    diskImage = {
      format = "qcow2";
    };
  };
}
