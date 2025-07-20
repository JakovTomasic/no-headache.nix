
TODO: project name? Naming is hard :(

A nix-build wrapper with simple API for configuring and running many virutal machines.

This is user documentation. For developer documentation see **TODO**.
This documentation also serves as a featureset that needs to be tested and maintained.

**TODO** write user documentation
- update everything when api is well formed

todo - write more in-detail documentation for configuring VMs. Here or in separate file in the doc.
- mention [this](https://search.nixos.org/options)

# An overview

todo: write short overview to get the whole high level context

todo: write tl;dr for setting-up everything
- mention `configs.nix` files
- mention default username and pass somewhere (here and in config doc)

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

### Run individual VM

todo - make custom command

Use `./result/bin/vm-name` to run the VM (replace it with your vm name. Note: write just the vm name. Don't run the available `run-vm-name-vm` command).
There are several options:
```bash
# Open a window of the VM:
./result/bin/vm-name

# Open it directly in the current terminal:
# To exit the VM just shutdown the VM and you'll return to your current terminal.
./result/bin/vm-name -nographic

# Run in background without opening any terminal
./result/bin/vm-name -display none &
```

### runAllVms

Running `runAllVms` runs all VMs
- todo

All arguments'll be forwarded to script for running each individual VM. See [Run individual vm](#run-individual-vm) to see options.

### buildAndRun

todo - remove this?



## SSH

todo - add example ssh key for exapmles/ so its easier to just try them

When using SSH in a VPN use it normally.
OpenSSH server is enabled by default.

To SSH into VM from your host machine without using VPN a port forwarding rule needs to be set to forward SSH connection from localhost to VM you want.
That's supported in the configs file.

Just define the `firstHostSshPort` option (e.g. set it to 2222) and build and run the VMs.

When a VM is running you can SSH into it by running appropriate command in the generated `results/bin/` directory.
For example, run `./result/bin/ssh-into-yourVmName`.

If you get error: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!" delete that known host from `~/.ssh/known_hosts` (you probably want to delete all hosts that begin with `[localhost]:some-port` there)


# QEMU

todo: napisi client doc i ostalo makni u dev doc

Virsh doesn't work because nix doesn't use it.
List all QEMU processes `ps aux | grep qemu` to see what VMs are running.
- todo: how to list processes? Write a script, if not anything else. (and ensure grep (package gnugrep) is available in the dev shell?)


# VPN

todo: napisi client doc i ostalo makni u dev doc

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


# Compatibility environments (compat envs)

Compatibility environments are more advanced feature for what can't be easily supported directly in `configs.nix` files.
The primary usecase is building FHS-compatible environments using nix `pkgs.buildFHSEnv` function.

You can write your own compat envs and modify existing ones.
All compat envs in `compat-envs/` directory should be complete and runnable without `flake.nix`.
Follow the general patterns used in `python-fhs.nix`.

Compatibility environments can also be built and tested outside of the VM.
To build the compat env just run `nix build -f path/to/compat/env.nix` and then enter interactive shell with `./result/bin/<name of the env>`
To exit the compat env shell just close the terminal or run `exit`.

_Warning_: activating FHS compat env in VM hides original `/etc` directory and overwrites it with another content (and probably some others, for compatibility reasons). That means you won't be able to access the files inside the original `/etc` dir.
So try not to use `/etc` dirs or other directories (e.g. don't use `environment.etc."code.py".source = ./code.py;`. Use custom `copyToHome` option instead).

## Python-FHS compat env

As python is expected to be most common usecase it's already supported in the project.
A `compat-envs/python-fhs.nix` file fully defines the compatibility environment for most python projects.
It also serves as an example for other projects.

Python FHS support greatly simplifies Python development and adds support for common commands like `pip install`.

You may modify and/or copy this file as needed.

As shown in `python-shared-venv` python example, you can have venv in the persistent shared directory.
That's useful when rebuilding VMs and resetting all VM storage as venv setup and package installation can take a long time.
This is a recommended approach if you expect VM config changes and reseting it's storage, especially in developing configs.nix.

### Usage

To include FHS environment in the VM follow these steps (in 'python' example, see 'python-fhs-env'):
1. add `(import ../../compat-envs/python-fhs.nix { inherit pkgs; })` in `environment.systemPackages` (you may need to change the relative path or use absolute path)
2. in `init.script` initialize and run python env:
    - initialize: `python-fhs -c 'init-python-venv -r requirements.txt'` (you may omit `-r requirements.txt`)
    - (if not using requirements.txt) run other setup commands like `python-fhs -c 'pip install numpy'`
    - run wanted command inside the environment `python-fhs -c 'source venv/bin/activate && <your command here>'` (e.g. `python-fhs -c 'source venv/bin/activate && python code.py'`)

These same commands can be run manually inside the VM.
In interactive VM shell you can also enter interactive python-fhs environment by using the name of the env (just run `python-fhs`).

Compatibility environments can also be built and tested outside of the VM.
To build the compat env on the host OS (outside of a VM) just run ``nix build -f compat-envs/python-fhs.nix`` and then enter interactive shell with `./result/bin/python-fhs`.

# Shared directory

With `virtualisation.sharedDirectories` option you can mount a host machine directory into VM directory, creating a shared directory.

You can also use shared directories a persistent storage that persists even configuration changes and VM storage deletions.
This is especially useful when creating VM config or generally when changes and storage deletions are frequent.

See `Python-FHS` and `python-shared-venv` for a complete example.

# Storage cleanup

todo - delete old stuff from nix store - gc

# Examples

todo - explain briefly and link to examples



