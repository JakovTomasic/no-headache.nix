{
  description = "Dev shell with isolated Tailscale session using SOCKS5 proxy";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.default = pkgs.mkShell {
        name = "tailscale-shell";

        buildInputs = with pkgs; [
          tailscale
        ];
      };
    });
}

