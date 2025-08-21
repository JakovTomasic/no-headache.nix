{ pkgs, customArgs, ... }:
let
  # use ssh key to avoid entering ssh password manually (tests need to run automatically)
  sshKeyFile = ../secrets/sshkeys/example_ssh_key.pub;
in
{
  # testing defaults
  aaa = {
    # testing the default count is 1
    # default username should be nixy
    firstHostSshPort = 2100; # testing ssh port forwarding
    # by default, nixos-config-virt is empty
    # by default, diskImage is null (no disk will be created)
    nixos-config = {
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ sshKeyFile ];
    };
  };

  bbb = {
    count = 2; # testing config != 1
    username = "userrr";
    firstHostSshPort = 2000; # testing ssh port forwarding in combination with count option
    copyToHome = {
      # Copy a file into /home/userrr/copiedFile
      "copiedFile" = ./testFile;
      # Copy a directory recursively into /home/userrr/copiedDir
      "copiedDir" = ./testDir;
    };
    # Disk should be created, but only when the 'makeDiskImages = true' (in your flake.nix). Exactly one image will be generated, even if 'count > 1'.
    diskImage = {
      format = "qcow2-compressed";
      additionalSpace = "0M"; # overwrite the default
    };
    init.script = ''
      # using script to test environment and testing init.script at the same time
      printf 'from init script' > ~/test-init.txt

      if [ ! -f "copiedFile" ]; then
          echo "Error: no copiedFile" > copyToHome-result
          exit 0
      fi
      if [ ! -d "copiedDir" ]; then
          echo "Error: no copiedDir" > copyToHome-result
          exit 0
      fi
      if [ ! -f "copiedDir/testFile2" ]; then
          echo "Error: no copiedDir/testFile2" > copyToHome-result
          exit 0
      fi

      printf 'success' > copyToHome-result
    '';
    nixos-config = {
      # Testing nixos-config in general...
      environment.systemPackages = with pkgs; [ python3 ];
      users.users.userrr.openssh.authorizedKeys.keyFiles = [ sshKeyFile ];
    };
  };

  # default option values, and tailscale
  ccc = {
    tailscaleAuthKeyFile = ../secrets/tailscale.authkey;
    init.script = ''
      printf "success" > /mnt/shared/ccc-init.script-result

      sleep 10 # wait for tailscale to initialize

      # Check if Tailscale daemon is running
      if ! pgrep -f tailscaled > /dev/null; then
          echo "Error: Tailscale daemon is not running." > /mnt/shared/tailscale-test-result
          exit 0
      fi

      # Check Tailscale status
      status=$(tailscale status --json 2>/dev/null)

      if [ -z "$status" ]; then
          echo "Error: Tailscale daemon is not running." > /mnt/shared/tailscale-test-result
          exit 0
      fi

      echo "success" > /mnt/shared/tailscale-test-result
    '';
    nixos-config = {
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ sshKeyFile ];
    };
    nixos-config-virt = {
      virtualisation.sharedDirectories = {
        testSharedDir = {
          source = "/tmp/no-headache-test/";
          target = "/mnt/shared";
        };
      };
    };
  };

  zzz = {
    # testing count = 0 disabled this machine
    count = 0;
  };
}
