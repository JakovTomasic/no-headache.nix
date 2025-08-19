# Development docs

These are some of my notes for commands and options used in the development of the project.
Should be useful for anyone trying to change anything in this project (except configs.nix and compat env files, which are user-configurable and don’t need this much knowledge of _under-the-hood_ systems).

If you don’t know what `configs.nix` or compat env files are or haven’t read the README.md, this is the wrong place to be right now. See you later, maybe :)

## Main devshell

The main devshell is the devshell used for developing this project itself, as well as changing and using custom configuration.
When entering devshell in flake, the flake copies the whole project directory (only git files) to the nix store.
When in the shell, you can print this with `nohead path`

Use `nix develop` (or `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop`) to enter shell with `nohead`.

Changing main devshell:
When you change anything from the main dev shell, you need to exit the current shell and re-enter it. That’ll trigger a rebuild.
On a build, all files are copied to nix store and used there, so changing e.g. `build.nix` file won’t take effect until you rebuild the shell.

Note: the project uses nix flakes, meaning it won't recognize any files that aren't added into git repo.

Note: `nohead init` uses the `user/flake.nix` which fetches `src/build.nix` file from the GitHub. For local development, you want to change that to point to your local file - just replace `"${no-headache}/src/build.nix"` with something like `./path/to/local/build.nix` (after `nohead init`).


## Basic run

how to start a VM only using nix (no nixos host needed):
```bash
# Build the VM
nix build -f ./configuration.nix
# This doesn’t work outside nixos: nix-build ${myFiles}/default.nix

# Run it
./result/bin/run-*-vm

# Or to open it directly in the current terminal:
./result/bin/run-*-vm -nographic
# to shutdown, just shutdown the VM and you’ll return to your current terminal

# Or run in background without opening any terminal
./result/bin/run-*-vm -display none &
```

Running the virtual machine will create a `<name of the VM>.qcow2` file in the current directory. **Delete this file** when you change the configuration.

This is just a basic example. Look at the nohead scripts to see what other options are used here.

This builds VM configuration, and by running it, you create an image for persistent storage. The image is just around 10 MB big because `/nix/store` is shared with the host.

## SSH

ssh into the VM by running on the host:
```bash
ssh -p 2222 nixy@localhost
# change port and username to match the real use case
```

## Testing

To run all tests just run `test/test.sh` script within environment that has `nohead` available.

## Compatibility environments (compat envs)

Building compat envs (any nix environments) inside a VM is slow. Always prebuild them.

Generally, building or installing anything nix-related in the VM is not recommended.

## QEMU

In this project, QEMU runs the virtual machines and generates qcow2 images because that’s what Nix uses.
To use other hypervisors, build a disk image.

Virsh doesn’t work because nix doesn’t use it.
Additionally, I don’t want to use virsh because it must be installed on the host system, meaning I can’t easily set it up in the environment, complicating project setup.

List all QEMU processes `ps aux | grep qemu` to see what VMs are running.

See written scripts for more advanced examples.

## Tailscale

How to add a server:
- Open the tailscale [web app](https://login.tailscale.com/admin/machines)
- Click “add device” -> Linux server
    - enable Ephemeral (automatically remove the device from your tailnet when it goes offline)
    - set Reusable auth key (so multiple machines can join using it)
    - Auth key expiration - choose as you wish
    - Generate script and copy `--auth-key` from it
- in your VM config, add `services.tailscale.enable = true;`
- `sudo tailscale up --login-server http://<HOST-IP>:8080 --authkey tskey-abc123...`
    - no `--login-server` if using online tailscale server
    - you can also copy this command from the tailscale web
- run two VMs
    - get IP from one and ping it from the other
    - get IP with `ip a` and then see `tailscale0` inet or just copy from the tailscale website GUI (or just `tailscale ip --4` or `ip addr show tailscale0`)

You can also find the Tailscale IP for other devices on your network by adding the device hostname after the command. For example: `tailscale ip raspberrypi`
- [source](https://tailscale.com/kb/1080/cli#ip)

Tailscale automatically assigns ip adresses and hostnames (giving it a suffix if two are the same)
- The suffixes can be a problem. They go `-1`, `-2`, etc.
- If I restart a VM (it has the same hostname), the suffix will be added, meaning I can’t get the IP address from a machine with such a hostname
- Ephemeral is a fix, but it removed the old machine only after some timeout, which is too long

## Git-crypt

All secrets must be put in the `secrets/` directory, which is added to [git-crypt](https://github.com/AGWA/git-crypt).

Check all protected files with `git-crypt status -e`.

When you download this repo, run `git-crypt unlock`.

TODO: test `git-crypt unlock`

# Other tips

`./result/bin/run-*-vm` has a lot of options. See that if needed. (reminder: don't run that directly, use `nohead run` command)

For debugging init.script, run `systemctl status script-at-boot` or `journalctl -u script-at-boot` inside the VM. Always check the full log with journalctl. systemctl crops only part of the log, and it might be very misleading.


