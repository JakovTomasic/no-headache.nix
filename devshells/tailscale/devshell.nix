
{ pkgs } :
pkgs.mkShell {
  name = "tailscale-shell";

  buildInputs = with pkgs; [
    tailscale
  ];
}

