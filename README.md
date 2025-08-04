
TODO: project name? Naming is hard :(


# An overview

VM.Nix (TODO: project name) is a development and testing environment powered by the Nix package manager, allowing you to define and run declarative, reproducible, and isolated NixOS virtual machines (VMs) and disk images with minimal setup. It’s ideal for projects that require per-VM configuration, quick and easy VMs setup, or clean state environments, all without the overhead of containers or cloud infrastructure.

Key Features:

- Single config file per setup – define multiple VMs in a single `configs.nix`.
- Zero manual dependency management – all tools are provisioned through Nix.
- Built-in dev shell – provides commands for building, running, and managing VMs.
- Tailscale integration – connect VMs over VPN effortlessly.
- Persistent shared directories – share files between host and VM.
- Compatibility environments – supports complex setups (e.g., Python with FHS and pip install).
- SSH & port forwarding – connect to VMs via SSH from host or over VPN.
- Build full disk images – for running in any hypervisor or on bare metal.
- Over 20,000 standrad NixOS options – use any NixOS options to configure your VMs.

This is user documentation. For developer documentation see [dev doc](./doc/dev.md).

## How it works

VM.Nix (TODO: project name) is a `nix-build` command wrapper with simple API for configuring and running many virutal machines.

- Nix is the only dependency required.
- All other tools (e.g., QEMU, build scripts) are pulled into an isolated dev shell.
- VMs are defined using a `configs.nix` file using simple Nix syntax.
- You control:
    - Number of VM instances
    - Username/password
    - Scripts to auto-run on boot
    - Port forwards for SSH
    - Shared folders and file copies
    - Optional VPN setup via Tailscale
    - Whole NixOS VMs configurations
- Python and other environments are supported using FHS-compatible environments.

# Setup

Setup steps. Tested on Ubuntu 24.04 LTS
- open terminal
- install Nix package manager [official instructions](https://nixos.org/download/)
    - run the provided command and follow instructions
        - install curl if needed (on Ubuntu: `sudo apt install curl`)
        - Both Single-user installation and Multi-user installation should work. For a bit easier usage install Multi-user installation (and Single-user for a bit faster install)
    - Nix should be installed. Run `nix --version` to verify
        - for Single-user installation you may need to run `. /home/ubuntu/.nix-profile/etc/profile.d/nix.sh` before using nix (as instructed after installation)
- download this project and `cd` into this project's root directory
- run `./enterdevshell.sh`
- build a configuration: `buildVms -c examples/vm-count-option/configs.nix`
- run all VMs with `runAllVms`
- that's it. Close the VMs and write your own configurations. Happy configuring!

## Tailscale

Optionally, setup tailscale server to connect VMs to.
This project has native support for tailscale with easy configuration.

In `secrets/` directory create a file named `tailscale.authkey` (or change `tailscaleAuthKeyFile` in `configs.nix` to use different name and path)
The file should just cointain a reusable tailscale key.

## SSH

Examples use provided public and private SSH keys.

**Do not use those keys** on publicly accessible devices, especially in production.
Generate new SSH keys and use *them* in your configurations.

Using example keys is OK when testing software on a device with closed TCP ports.
More specifically, ports defined with `firstHostSshPort` option (and sequential ports, depending on `count` option) must be closed on the host machine.

# Examples

Full runnable example of many configurations and usecases are in the `examples` directory.

Usage instructions below reference individual examples.

For examples that require SSH, an example SSH public and private keys have been used. Both public and private keys are available in the `example/sshkeys` directory.
Add private key to your host machine with `ssh-add examples/sshkeys/private_key_file_name`.
These keys are provided just for rully reproducible examples with zero setup steps. Don't use them in your configs.

# Usage

The next steps explain how to use this project.

## Enter the development shell

All commands and environment is available within the dev shell.
To enter the dev shell just run the `enterdevshell.sh` command (e.g. from the project's root directory run `./enterdevshell.sh`).

To exit the dev shell just close the terminal or run `exit`.


## Configurations

By convention, all VMs' configurations are contained in a single `configs.nix` file.

You can write custom `configs.nix` files (you can also change the file name) or use example configs provided in the `examples` directory.

For documentation on writing configurations, see [Writing configurations](./doc/configuring.md)

## Commands

These commands are built-in to the development shell and can be run like any global commands (while in the shell).

todo - should all this be single command e.g. vmnix run --all

### buildVms

Running `buildVms` builds all virtual machine configurations.

By default, the command uses `configs.nix` file from the current directory.
To specify custom path to the configs.nix file run e.g. `buildVms -c examples/python/configs.nix` or `buildVms -c ../configs-with-custom-name.nix`.

You can also run `buildVms -h` or `buildVms --help` for (very) short overview.

This command will create symlink to nix store named `result` in the current directory (the `result` is practically a new created directory).
You can leave that symlink. You'll never need to use it directly, but you may if curious.
The result directory contains all built outputs with all configurations and executable files. All executable files are located in `result/bin/` directory.
Every time the VMs are built, the result symlink is overwritten with the new results.

Build outputs persist in the nix store even after you delete the result symlink. See [Storage cleanup](#storage-cleanup) section for how to remove old files.
That means you can have and use multiple results. E.g. you can:
- build VM from `configs1.nix`. The `result` symlink will be created
- rename it to result1 so it doesn't get overwritten (run `mv result result1`)
- build VM again, but use `configs2.nix`
- optionally, rename new result, too. For consistency (`mv result result2`)
- you now have two result symlink directories. Each for separate configs.

### Running VMs

There are few ways to run VMs from built configurations.

Generally, by running a VM a image for persistent storage `name_of_the_machine.qcow2` will be created in the current directory.
For simple configs, the image is just around 10 MB big because `/nix/store` is shared with the host.

**Delete qcow2 file** when you change the configuration (before running the VM with different configuration).
*Note*: commands for running VMs will print warning and remind you if you forget to remove qcow2 file.

Default username for the VM is `nixy` and the password is `nixos`, unless changed in your `configs.nix`.

Each machine has defined following environment variables:
- *MACHINE_BASE_NAME* – Base name of the machine. Equals to the name in the `configs.nix` file.
- *MACHINE_INDEX* – Index of this machine in the list of virtual machines with the same configuration (only important if `count` option is used).
- *MACHINE_NAME* – Full name of the machine. Equals to the name in the `configs.nix` file and index if `count` option is used.
- *MACHINE_TYPE* – "image" if the machine is build as disk image and "virtual" if it's build as a virtual machine.

### Run individual VM

Use `./result/bin/vm-name` to run the VM (replace it with your vm name. Note: write just the vm name. Don't run the available `run-vm-name-vm` command).
There are several options:
```bash
# Open a window of the VM:
./result/bin/vm-name &

# Open it directly in the current terminal:
# To exit the VM just shutdown the VM and you'll return to your current terminal.
./result/bin/vm-name -nographic

# Run in background without opening any terminal
./result/bin/vm-name -display none &
```

### runAllVms

Running `runAllVms` runs all VMs from the last built `configs.nix`.

All arguments'll be forwarded to script for running each individual VM. See [Run individual vm](#run-individual-vm) to see options.

### listRunningVMs

This command lists names of all (QEMU) VMs that are currently running, one per line.

Example: `listRunningVMs`

### stopVm

Running this command stops VM with defined name.

Example: `stopVm hemisphere-1` (where VM is called hemisphere-1, from `vm-count-option`)

### Build disk images

Run the build command with `--images` argument to, along VMs, build the full disk images, too.
Full command example: `buildVms -c examples/disk-images/configs.nix --images`

About disk images:
- Image will be built only for configurations with defined `diskImage` option.
- This project doesn't implement method to run images. Run them in supported hypervisors or on bare metal.
- For configuring images see option `diskImage` in [configuration instructions](./doc/configuring.md).
- Image generator ignores `count` option. It'll generate single image for each configuration with defined `diskImage` option.
  - That means environment variable *MACHINE_INDEX* is always 1 and *MACHINE_NAME* is equal to *MACHINE_BASE_NAME*.
- Minimal *raw* image (e.g. the ones from the *disk-images* example) is 3.1 GB large. Image file size for *qcow2* format is 1.7 GB and *qcow2-compressed* format 550 MB.
- The generated images will remain in the nix store until you clean it with `nix store gc` (see [Storage cleanup](#storage-cleanup)).

Symlink to built image will be generated in the `result` directory.
Copy it somewhere else to use it. Also see the image file permissions and file owner.


## SSH

When using SSH in a VPN use it normally.
OpenSSH server is enabled by default.

To SSH into VM from your host machine without using VPN a port forwarding rule needs to be set to forward SSH connection from localhost to VM you want.
That's supported in the configs file.
Full example of such `configs.nix` is provided in the `ssh-from-host` example.

Just define the `firstHostSshPort` option (e.g. set it to 2222) and build and run the VMs.

When a VM is running you can SSH into it by running appropriate command in the generated `result/bin/` directory.
For example, run `./result/bin/ssh-into-yourVmName`.

If you get error: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!" delete that known host from `~/.ssh/known_hosts` (you probably want to delete all hosts that begin with `[localhost]:some-port` there). That error shouldn't happen if using only the `./result/bin/ssh-into-yourVmName` scripts.


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
To build the compat env just run `nix --extra-experimental-features nix-command build -f path/to/compat/env.nix` and then enter interactive shell with `./result/bin/<name of the env>`.
(If you get get error when running result bin file "bwrap: setting up uid map: Permission denied" you can enter the shell as root user via `sudo ./result/bin/<name of the env>`, which is not ideal but should work.)
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
To build the compat env on the host OS (outside of a VM) just run ``nix --extra-experimental-features nix-command build -f compat-envs/python-fhs.nix`` and then enter interactive shell with `./result/bin/python-fhs`.

# Shared directory

With `virtualisation.sharedDirectories` option you can mount a host machine directory into VM directory, creating a shared directory.

You can also use shared directories a persistent storage that persists even configuration changes and VM storage deletions.
This is especially useful when creating VM config or generally when changes and storage deletions are frequent.

See `Python-FHS` and `python-shared-venv` for a complete example.

# Storage cleanup

To remove old unused files from the nix store:
- optionally, first remove the result symlink if you wish to delete those files, too (all nix store files/dirs that have symlinks point to them won't be deleted)
- run nix store garbage collector `nix store gc` (it may take few minutes to complete)
- old files, build results and unused packages will be deleted


