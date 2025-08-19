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
    };
  };
}

