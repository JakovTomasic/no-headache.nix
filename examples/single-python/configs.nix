{ pkgs, ... }:
{
  python-code = {
    init.script = ''
      python /etc/code.py
    '';
    # Example: you can define custom username.
    username="pythonguy";

    nixos-config = {
      environment.etc."code.py".source = ./code.py;

      environment.systemPackages = with pkgs; [ python3 ];
    };
  };
}

