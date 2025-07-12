
# Development docs

These are some of my notes for commands and options used in the development of the project.


## Basic run

how to start a VM only using nix (no nixos host needed):
```bash
# Build the VM
nix run nixpkgs#nixos-rebuild -- build-vm -I nixos-config=./configuration.nix

# Run it
./result/bin/run-*-vm
# Or to open it directly in the current terminal:
./result/bin/run-*-vm -nographic
# to shutdown just shutdown the VM and you'll return to your current terminal
# Or run in background without opening any terminal
./result/bin/run-*-vm -display none &
```
Running the virtual machine will create a `nixos.qcow2` file in the current directory. **Delete this file** when you change the configuration.

This is just a basic example. See running scripts to see what other options are used here.

This builds VM configuration and by running it you create a image for persistent storage. Image is just around 10 MB big because `/nix/store` is shared with the host.


## printFilesPath

In the dev shell, command `printFilesPath` prints where in the nix store are all dev shell files.


