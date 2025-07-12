
todo: write instructions for what you do and how to recreate it

This is user documentation. For developer documentation see **TODO**.
This documentation also serves as a featureset that needs to be tested and maintained.

**TODO** write user documentation
- update everything when api is well formed


# An overview

todo: write short overview to get the whole high level context

todo: write tl;dr for setting-up everything

# Setup

## Install Nix

First, install Nix package manager on your machine

todo

## Download this repo

todo - don't move it?

## Tailscale

Optionally, setup tailscale server to connect VMs to.
This project has native support for tailscale with easy configuration.

In `secrets/` directory create a file named `tailscale.authkey` (or change `tailscaleAuthKeyFile` in `configs.nix` to use different name and path)
- the file should just cointain a reusable tailscale key

todo - use it in config? Or not needed. How to config tailscale?


# Usage

The next steps explain how to use this project.

todo

## Enter the development shell

All commands and environment is available within the dev shell.
To enter the dev shell just run the `enterdevshell.sh` command (e.g. from the project's root directory run `./enterdevshell.sh`).

To exit the dev shell just close the terminal or run `exit`.

todo - how to check if in the dev shell?


## Example configurations

By convention, all VMs' configurations are contained in a single `configs.nix` file.

You can write custom `configs.nix` files (you can also change the file name) or use example configs provided in the `examples` directory.

## Commands

todo - prepared commands

todo - should all this be single command e.g. vmnix run --all

### buildVms

Running `buildVms` builds all virtual machine configurations.

By default, the command uses `configs.nix` file from the current directory.
To specify custom path to the configs.nix file run e.g. `buildVms -c examples/single-python/configs.nix` or `buildVms -c ../configs-with-custom-name.nix`.

You can also run `buildVms -h` or `buildVms --help` for (very) short overview.

This command will create symlink to nix store named `result` in the current directory.
You can leave that symlink. You'll never need to use it directly, but you may if curious.
- todo: explain result dir? Not here but somewhere.

### Running VMs

There are few ways to run VMs from built configurations.

Generally, by running a VM a image for persistent storage `name_of_the_machine.qcow2` will be created in the current directory.
For simple configs, the image is just around 10 MB big because `/nix/store` is shared with the host.

**Delete qcow2 file** when you change the configuration (before running the VM with different configuration).
*Note*: commands for running VMs will print warning and remind you if you forget to remove qcow2 file.

todo - background and windows mode
- and explain username and password
- or put this somewhere

### run individual vm

todo - make custom command

for now use `./result/bin/vm-name` (just the vm name. Not run-vm-name-vm)

todo - explain options/params

### runAllVms

todo - join this command with run? E.g. run --all

Running `runAllVms`

todo - explain options/params

### buildAndRun

todo - remove this?



## SSH

When using SSH in a VPN use it normally.
OpenSSH server is enabled by default.

To SSH into VM from your host machine without using VPN a port forwarding rule needs to be set to forward SSH connection from localhost to VM you want.
That's supported in the configs file.

Just define the `firstHostSshPort` option (e.g. set it to 2222) and build and run the VMs.

When a VM is running you can SSH into it by running appropriate command in the generated `results/bin/` directory.
For example, run `./result/bin/ssh-into-yourVmName`.

If you get error: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!" delete that known host from `~/.ssh/known_hosts` (you probably want to delete all hosts that begin with `[localhost]:some-port` there)


# QEMU

Virsh doesn't work because nix doesn't use it.
List all QEMU processes `ps aux | grep qemu` to see what VMs are running.
- todo: how to list processes?


# VPN

todo: problematicno dodjeljivanje imena tailscale doda suffix `-1`, `-2`, itd ako dvaput upalis vm sa istim imenom (cak i ako prvo ugasis ovaj prije)
- ima fix - Ephemeral - ali tek nakon sat vremena se makne sa tailscale

Use tailscale. You can even host your own server with headscale

todo: validate this, update for my new api
- open tailscale web app
- add device - linux server
    - set Reusable auth key - so multiple machines can join using it
    - enable Ephemeral - Automatically remove the device from your tailnet when it goes offline
    - Auth key expiration - choose as you wish
    - generate scrip and copy `--auth-key` from it
- in your VM config, add `services.tailscale.enable = true;`
- `sudo tailscale up --login-server http://<HOST-IP>:8080 --authkey tskey-abc123...`
    - no `--login-server` if using online tailscale server
    - you can also copy this command from tailscale web
- run two VMs
    - get ip from one and ping it from the other
    - get IP with `ip a` and then see `tailscale0` inet or just copy from the tailscale website gui (or just `tailscale ip --4` or `ip addr show tailscale0`)

`services.tailscale.authKeyFile`
- A file containing the auth key. **Tailscale will be automatically started if provided.**

You can also find the Tailscale IP for other devices on your network by adding the device hostname after the command. For example: `tailscale ip raspberrypi`
- [source](https://tailscale.com/kb/1080/cli#ip)

Tailscale automatically assigns ip adresses and hostnames (giving it suffix if two are the same)


# Other notes

`./result/bin/run-*-vm` ima puno opcija. Baci oko ako zatreba

qcow2 je image
- https://www.linux-kvm.org/page/Qcow2

for debugging init.script run `systemctl` and `journalctl` inside the VM and `systemctl status script-at-boot` or `journalctl -u script-at-boot`

you can't use `~` in `init.script`
- todo: implement alternative? Like `$NIXY` or `$HOME`


