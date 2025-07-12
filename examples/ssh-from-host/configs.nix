{ pkgs, ... }:
# optionally, define users.users.your-username-by-default-nixy.openssh.authorizedKeys.keys = "put your public ssh key here"
{
  # Every VM has one special program to see if ssh was correct.
  # These VM ports mustn't conflict.
  # Advice: use more distant firstHostSshPort values so you can change count without conflicts. E.g. 2100, 2200, 2300, ...

  # connect with sshVm bird
  bird = {
    firstHostSshPort = 2220; # used host port will be 2220
    nixos-config = {
      environment.systemPackages = with pkgs; [ jq ];
    };
  };

  # connect with sshVm turtle-1 or sshVm turtle-2
  turtle = {
    count = 2;
    firstHostSshPort = 2221; # used host port will be 2221 for first VM (turtle-1) and 2222 for the second VM (turtle-2)
    nixos-config = {
      environment.systemPackages = with pkgs; [ bat ];
    };
  };

  # connect with sshVm fish
  fish = {
    username="fish";
    firstHostSshPort = 2223; # used host port will be 2223. This can't be 2222 because the second turtle will use that.
    nixos-config = {
      environment.systemPackages = with pkgs; [ yq ];
    };
  };

  # cannot connect to this via SSH because it doesn't have firstHostSshPort
  # John is invisible to the SSH
  john = {
    nixos-config = {
      environment.systemPackages = with pkgs; [ htop ];
    };
  };
}
