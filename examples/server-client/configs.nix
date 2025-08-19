{ pkgs, ... }:
let
  # you can define variables here in let...in for less code duplication

  tsKeyFile = ../../secrets/tailscale.authkey;

  # Common shared directory so I don't have to enter the machine (e.g. via SSH or terminal GUI) every time.
  # Just read this directory on host for viewing logs.
  sharedDirectory = {
    debugSharedDir = {
      # Absolute path to host OS path of dir to be shared
      # Important: you need to create this directory before starting this VM
      # use: mkdir -p /tmp/my-nixos-vms-shared/server-client
      source = "/tmp/my-nixos-vms-shared/server-client";
      # Absolute path to virtual machine path
      target = "/mnt/shared";
    };
  };
in
# firstHostSshPort option won't work when connected to VPN because it won't route SSH from host OS. Host needs to connect to the tailscale, too.
{
  client = {
    tailscaleAuthKeyFile = tsKeyFile;
    init.script = ''
      echo "Starting python client script..." &> ~/output.txt
      python ~/client.py &>> ~/output.txt
    '';
    copyToHome = {
      # Copy the script into VM ~/client.py
      "client.py" = ./client.py;
    };
    nixos-config = {
      environment.systemPackages = with pkgs; [ python3 ];
    };
    nixos-config-virt = {
      virtualisation.sharedDirectories = sharedDirectory;
    };
  };
  server = {
    tailscaleAuthKeyFile = tsKeyFile;
    init.script = ''
      echo "Starting python server script..." &> ~/output.txt
      python ~/server.py &>> ~/output.txt
    '';
    copyToHome = {
      # Copy the script into VM ~/server.py
      "server.py" = ./server.py;
    };
    nixos-config = {
      environment.systemPackages = with pkgs; [ python3 ];

      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
    nixos-config-virt = {
      virtualisation.sharedDirectories = sharedDirectory;
    };
  };
}

