{ pkgs, ... }:
{
  python-code = {
    custom.pythonScript = "/etc/code.py";
    custom.hostName = "python-code";
    init.script = ''
      python /etc/code.py
    '';
    nixos-config = {
      # TODO: this may not work
      environment.etc."code.py".source = ./code.py;

      environment.systemPackages = with pkgs; [ python3 ];
    };
  };
}

