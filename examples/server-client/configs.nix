{ pkgs, ... }:
let
  # you can define variables here in let ... in

  # Change when you generate another ssh key (or add new keys to the lists below).
  sshkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs";
in
{
  client = {
    tailscaleAuthKeyFile = ./secrets/tailscale.authkey;
    nixos-config = {
      # Deploy the script into /etc/client.py
      # TODO: this may not work
      environment.etc."client.py".source = ./client.py;

      users.users.pythonguy.openssh.authorizedKeys.keys = [ sshkey ];
    };
  };
  server = {
    tailscaleAuthKeyFile = ./secrets/tailscale.authkey;
    nixos-config = {
      # Deploy the script into /etc/server.py
      environment.etc."server.py".source = ./server.py;

      users.users.pythonguy.openssh.authorizedKeys.keys = [ sshkey ];
    };
  };
}

