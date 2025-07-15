{
  description = "Main flake for whole project and with a dev shell encapsulating needed files and executables";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.default = import ./devshells/main/devshell.nix { inherit pkgs; };
    });
}

