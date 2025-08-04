
# Development docs

These are some of my notes for commands and options used in the development of the project.
Should be useful for anyone trying to change anything in this project (except configs.nix and compat env files which are user configurable and don't need this much knowledge of _under the hood_ systems).

If you don't know what are `configs.nix` or compat env files or haven't read the README.md this is a wrong place to be right now. See you later, maybe :)


## Changing main devshell

When you change anything from the main dev shell you need to exit current shells and re-enter them. That'll trigger a rebuild.
On a build, all files are copied to nix store and used there so changing e.g. default.nix won't take effect until you rebuild the shell.

The main devshell is the devshell used for developing this project itself as well as changing and using custom configuration.


## Basic run

how to start a VM only using nix (no nixos host needed):
```bash
# Build the VM
nix build -f ./configuration.nix
# This doesn't work outside nixos: nix-build ${myFiles}/default.nix

# Run it
./result/bin/run-*-vm
# Or to open it directly in the current terminal:
./result/bin/run-*-vm -nographic
# to shutdown just shutdown the VM and you'll return to your current terminal
# Or run in background without opening any terminal
./result/bin/run-*-vm -display none &
```
Running the virtual machine will create a `<name of the VM>.qcow2` file in the current directory. **Delete this file** when you change the configuration.

This is just a basic example. See running scripts to see what other options are used here.

This builds VM configuration and by running it you create a image for persistent storage. Image is just around 10 MB big because `/nix/store` is shared with the host.


## printFilesPath

In the dev shell, command `printFilesPath` prints where in the nix store are all dev shell files.

## SSH

ssh into the vm by running on the host:
```bash
ssh -p 2222 nixy@localhost
# change port and username to match the real usecase
```

## Testing

todo - write tests - like examples but automated
- automatically shut down VM and check if test fails if everything is shutdown (automatically)


## Compatibility environments (compat envs)

Building compat envs (any nix environments) inside VM is slow. Always prebuild them.

Generally, building or installing anything nix-related in the VM is not recommended.

## QEMU

Virtual machines in this project are run in QEMU and generate qcow2 images because that's what Nix uses.
To use other hypervisors, build a disk image.

Virsh doesn't work because nix doesn't use it.
Additionally, I don't want to use virsh because it must be installed on host system meaning I can't easily set it up in the environment, complicating project setup.

List all QEMU processes `ps aux | grep qemu` to see what VMs are running.
See written scripts for more advanced examples.



# Other tips

`./result/bin/run-*-vm` has a lot of options. See that if needed.

for debugging init.script run `systemctl status script-at-boot` or `journalctl -u script-at-boot` inside the VM.
- always check full log with journalctl. systemctl crops only part of the log and it might be very misleading


