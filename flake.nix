{
  description = "Main flake for whole project and with a dev shell encapsulating needed files and executables";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      absPath = self.outPath;  # This is the absolute path of the flake (in the nix store)
    in {
      devShells.default = import ./devshells/main/devshell.nix { inherit pkgs system absPath; };
      devShells.tailscale = import ./devshells/tailscale/devshell.nix { inherit pkgs; };
    });
}

