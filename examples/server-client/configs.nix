{ pkgs, ... }:
let
  # you can define variables here in let...in for less code duplication

  # Change when you generate another ssh key (or add new keys to the lists below).
  sshKeyFile = ../sshkeys/example_ssh_key.pub;

  tsKeyFile = ./secrets/tailscale.authkey;
in
{
  client = {
    tailscaleAuthKeyFile = tsKeyFile;
    init.script = ''
      # TODO: remove logging
      echo "asdf" &> /home/nixy/output2.txt
      python ~/client.py &> /home/nixy/output.txt
    '';
    copyToHome = {
      # Copy the script into ~/client.py
      "client.py" = ./client.py;
    };
    nixos-config = {
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ sshKeyFile ];
      environment.systemPackages = with pkgs; [ python3 ];
    };
  };
  server = {
    tailscaleAuthKeyFile = tsKeyFile;
    init.script = ''
      # TODO: remove logging
      echo "asdf" &> /home/nixy/output2.txt
      python ~/server.py &> /home/nixy/output.txt
    '';
    copyToHome = {
      # Copy the script into ~/server.py
      "server.py" = ./server.py;
    };
    nixos-config = {
      users.users.nixy.openssh.authorizedKeys.keyFiles = [ sshKeyFile ];
      environment.systemPackages = with pkgs; [ python3 ];

      networking.firewall.allowedTCPPorts = [ 5000 ];
    };
  };
}

