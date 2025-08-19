
# no-headache.nix

**N**otably **O**pinionated yet **H**ighly **E**xtensible **A**nd **D**eclarative **A**pproach for **C**onfiguring **H**undreds of **E**nvironments (using Nix)

no-headache.nix is a development and testing environment powered by the Nix package manager, allowing you to define and run multiple declarative, reproducible, and isolated NixOS virtual machines (VMs) and disk images with minimal setup. It’s ideal for projects that require per-VM configuration, quick and easy VM setup, or clean state environments, all without the overhead of complex virtualisation systems or cloud infrastructure.

Key Features:

- Single config file per setup – define multiple VMs in a single `configs.nix`.
- Zero manual dependency management – all tools are provisioned through Nix.
- Fully declarative and reproducible – uses Nix with Flakes.
- Built-in dev shell – provides easy `nohead` command for building, running, and managing VMs.
- Tailscale integration – connect VMs over VPN effortlessly.
- Persistent shared directories – share files between host and VM.
- Compatibility environments – supports complex setups (e.g., Python with FHS and pip install).
- SSH & port forwarding – connect to VMs via SSH from host or over VPN.
- Build full disk images – for running in any hypervisor or on bare metal.
- Over 20,000 standard NixOS options – use any NixOS options to configure your VMs.
- Runs wherever the Nix package manager does – works on all popular Linux distributions, not just NixOS.

This is user documentation. For developer documentation, see [dev doc](./doc/dev.md).

## How it works

no-headache.nix is a `nix build` command wrapper with a simple interface for configuring and running many virtual machines.

- Nix is the only dependency required.
- All other tools (e.g., QEMU, build scripts) are installed automatically through Nix.
- VMs and disk images are defined using a `configs.nix` file using simple Nix syntax.
- You control:
    - Number of VM instances
    - Username/password
    - Scripts to auto-run on boot
    - Port forwards for SSH
    - Shared folders and file copies
    - Optional VPN setup via Tailscale
    - Full independent disk image build options
    - Whole NixOS VM configurations
- Python and other environments are supported using FHS-compatible environments (or using your custom configurations).

# Setup

Setup steps. Tested on Ubuntu 24.04 LTS
- open terminal
- install Nix package manager [official instructions](https://nixos.org/download/)
    - run the provided command and follow instructions
        - install curl if needed (on Ubuntu: `sudo apt install curl`)
        - Both Single-user installation and Multi-user installation should work. For a bit easier usage, install Multi-user installation
    - Run `nix --version` to verify Nix is installed
        - for Single-user installation, you may need to run `. /home/ubuntu/.nix-profile/etc/profile.d/nix.sh` before using nix (as instructed after installation)
- run `nix develop github:JakovTomasic/no-headache.nix` to enter into development shell that has the `nohead` command (if you get an error, run `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop github:JakovTomasic/no-headache.nix`)
    - to install the project permanently, run `nix --extra-experimental-features nix-command --extra-experimental-features flakes profile install github:JakovTomasic/no-headache.nix` or add it to your nix configuration
- run `nohead init` to create a new project (optionally, rename the created directory) and cd into the created directory (the root directory of your project)
    - if the project is tracked with Git, run `git-crypt init` and see detailed instructions below (enter the development shell if you don't have it installed)
- build an example configuration: `nohead build -c .#vm-count-option` (run this inside the generated directory)
- run all VMs with `nohead runall`
- stop all VMs with `nohead stopall`
- that's it! Write your own configurations. Happy configuring!


## Tailscale

Optionally, setup tailscale server to connect VMs to.
This project has native support for tailscale with easy configuration.

Recommended steps:
- Open the tailscale [web app](https://login.tailscale.com/admin/machines)
- Click "add device" -> Linux server
    - enable Ephemeral (automatically remove the device from your tailnet when it goes offline)
    - set Reusable auth key (so multiple machines can join using it)
    - Auth key expiration - choose as you wish
    - Generate script and copy `--auth-key` from it
- In the `secrets/` directory, create a file named `tailscale.authkey` (or change `tailscaleAuthKeyFile` in `configs.nix` to use a different name and path). The file should just contain a reusable tailscale key.
- When writing configuration, set the `tailscaleAuthKeyFile` option.

## SSH

To use ssh features (the `nohead ssh` command) you need to install and setup ssh on your device.

# Examples

Full runnable examples of many configurations and use cases are in the `examples` directory.

Usage instructions below reference individual examples.

# Usage

The next steps explain how to use this project.

Everything can be run via the `nohead` command that aims to be so simple that, once you get familiar with it, you don't even need to use your head.

You can access the command in a few ways:
- open temporary bash shell (development environment) that has `nohead` by running `nix develop github:JakovTomasic/no-headache.nix`
    - if you get an error, use the full command: `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop github:JakovTomasic/no-headache.nix`
    - to exit the dev shell, just close the terminal or run `exit`.
    - once you run `nohead init`, you can enter the reproducible dev shell locally by running `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop` in the project root directory. This is recommended over always accessing the latest shell from GitHub.
- install the project permanently by running `nix --extra-experimental-features nix-command --extra-experimental-features flakes profile install github:JakovTomasic/no-headache.nix` or add it to your machine's Nix configuration

## Configurations

By convention, all VMs' configurations are contained in a single `configs.nix` file.

You can write custom `configs.nix` files (you can also change the file name) or use example configs provided in the `examples` directory.

For documentation on writing configurations, see [Writing configurations](./doc/configuring.md)

An empty `configs.nix` file is created with `nohead init` in the root directory of the project and added to the `flake.nix`.
To use a config file, you must define it in the `flake.nix`.

## Commands

Use the `nohead` command for everything.
If don't want to use your precious brain cells for remembering subcommands, you can always run `nohead help` (or just `nohead` or `nohead --help` or `nohead h` or even `nohead whatisgoingon`, we try not to (over)think around here).

### build

Running `nohead build` builds all virtual machine configurations from the selected configs file.

To select a configs file, use `nohead build -c ./path/to/flake/dir#config-name` where:
- The part before # is a relative or absolute path to the directory where the flake.nix file is (the root directory of the no-headache project)
- The part after # is a config name as defined in the flake.nix file (it points to a specific configs.nix file).
- For example, `nohead build -c .#default` from the project's root directory

You can also run `nohead build --help` for a (very) short overview.

### Result

The build subcommand will create a symlink to the nix store named `result` in the current directory (by default).
The result directory contains all built outputs with all configurations and executable files. You don't need to directly use its contents.
Every time the VMs are built, the result symlink is overwritten with the new results.

Build outputs persist in the nix store even after you delete the result symlink. See the [Storage cleanup](#storage-cleanup) section for how to remove old files.
That means you can have and use multiple results. E.g., you can:
- build a VM from `configs1.nix` using `nohead build -c configs1.nix`. The `result` symlink will be created (in the project's root dir)
- rename it to result1 so it doesn't get overwritten (run `mv result result1`)
- build a VM again, but use `configs2.nix` (`nohead build -c configs2.nix`)
- optionally, rename the new result, too. For consistency (`mv result result2`)
- you now have two result symlink directories. Each for separate configs.
- to use commands in each of them, provide the `--result` option. E.g. `nohead -r result2 run server`

Alternatively, use the `nohead --result` (or -r) option:
- `nohead -r result1 build -c configs1.nix` - build and generate result1 in the current directory
- `nohead -r result2 build -c configs2.nix` - same for the second config
- now use the two directories. E.g. run VMs from the first config with `nohead -r result1 runall` and from the second with `nohead -r result2 runall`

### Run VMs

There are few ways to run VMs from built configurations (the result directory created with `nohead build`).

Generally, by running a VM, an image for persistent storage `name_of_the_machine.qcow2` will be created in the current directory.
For simple configs, the image is just around 10 MB big because `/nix/store` is shared with the host.

**Delete qcow2 file** when you change the configuration (before running the VM with a different configuration).

Default username for the VM is `nixy` and the password is `nixos`, unless changed in your `configs.nix`.

Each machine has defined the following environment variables:
- *MACHINE_BASE_NAME* – Base name of the machine. Equals to the name in the `configs.nix` file.
- *MACHINE_INDEX* – Index of this machine in the list of virtual machines with the same configuration (only important if the `count` option is used).
- *MACHINE_NAME* – Full name of the machine. Equals to the name in the `configs.nix` file and index if the `count` option is used.
- *MACHINE_TYPE* – equals to "image" if the machine is build as a disk image and "virtual" if it's built as a virtual machine.

Run an individual VM with `nohead run <vm-name>` (e.g., `nohead run server`). Optional arguments:
- `-w` or `--window` - run VM in window mode (default)
- `-n` or `--noui` - run VM in the background
- if provided, only one of the above arguments can be used, and it needs to be used as the first argument/flag after the subcommand
- any other arguments will be forwarded to QEMU, so use any QEMU arguments you'd like

Run all VMs at the same time with `nohead runall`.
All arguments will be forwarded to the script for running each individual VM. See options above.

### Build disk images

To build a disk image, you must set `makeDiskImages = true;` to the desired config in the flake.nix file and then run the `nohead build` command.
See the `disk-images` example and build it with `nohead build -c .#disk-images`.

About disk images:
- Image will be built only for configurations with defined `diskImage` option.
- This project doesn't implement a method to run images. Run them in supported hypervisors or on bare metal.
- For configuring images, see the `diskImage` option in [configuration instructions](./doc/configuring.md).
- Image generator ignores the `count` option. It'll generate a single image for each configuration with a defined `diskImage` option.
    - That means environment variable *MACHINE_INDEX* is always 1 and *MACHINE_NAME* is equal to *MACHINE_BASE_NAME*.
- A minimal *raw* image (e.g. the ones from the *disk-images* example) is approximately 3.1 GB large. The image file size for the *qcow2* format is 1.7 GB, and the *qcow2-compressed* format is 550 MB.
- The generated images will remain in the nix store until you clean it with `nix store gc` (see [Storage cleanup](#storage-cleanup)).

Symlink to built image will be generated in the `result` directory (named `<name-of-the-machine>.qcow2`).
Copy it somewhere else to use it. Also check the image file permissions and file owner.

## SSH

When using SSH in a VPN, use it normally.
OpenSSH server is enabled by default.

To SSH into a VM from your host machine without using VPN, a port forwarding rule needs to be set to forward the SSH connection from localhost to the VM you want.
That's supported in the configs file.
A full example of such `configs.nix` is provided in the `ssh-from-host` example.

Just define the `firstHostSshPort` option (e.g. set it to 2222) and build and run the VMs.

When a VM is running, you can SSH into it by running `nohead ssh <vm-name> [other standard ssh options...]`.
E.g. ssh into a machine with `nohead ssh earth` or just run single command with `nohead ssh earth 'echo $MACHINE_NAME'`.

## VPN

See setup steps before using tailscale in your project or running examples that require it.

When `tailscaleAuthKeyFile` option is set, Tailscale will automatically be initialized in the VM/image.

How to connect to tailscale:
- If you don't have tailscale installed on your host machine, enter shell with tailscale by running `nix --extra-experimental-features nix-command --extra-experimental-features flakes develop .#tailscale` from the project root directory.
- Run `sudo tailscaled` to start the tailscale service.
- Open a new shell (new terminal), and enter the tailscale environment with the same command
- In the new shell, run `sudo tailscale up` and auth via browser, or run `sudo tailscale up --authkey=tskey-xxxxxxxxxxxxxxxx` if you want to use a key

Verify tailscale is running:
- `tailscale ip`
- `tailscale status` (this will show all devices in the virtual network)
- `ip a` should have tailscale0

Now you can use SSH to connect to other devices in the tailscale network
- note: use `ssh username@ip-address` - the default username is nixy.
- you can even connect via `ssh username@hostname` (hostname is equal to machine name in the configs.nix)

When you're done, run:
```bash
sudo tailscale down
sudo pkill tailscaled
```

# Compatibility environments (compat envs)

Compatibility environments are a more advanced feature for software that can't be easily supported directly in `configs.nix` files.
The primary use case is building FHS-compatible environments using nix `pkgs.buildFHSEnv` function.

You can write your own compat envs and modify existing ones.
All compat envs in the `compat-envs/` directory should be complete and runnable without `flake.nix`.
Follow the general patterns used in `python-fhs.nix`.

Compatibility environments can also be built and tested outside the VM.
To build the compat env, just run `nix --extra-experimental-features nix-command build -f path/to/compat/env.nix` and then enter interactive shell with `./result/bin/<name of the env>`.
(If you get an error when running the result bin file "bwrap: setting up uid map: Permission denied" you can enter the shell as the root user via `sudo ./result/bin/<name of the env>`, which is not ideal but should work.)
To exit the compat env shell, just close the terminal or run `exit`.

_Warning_: activating FHS compat env in VM hides the original `/etc` directory and overwrites it with other content (and probably some others, for compatibility reasons). That means you won't be able to access the files inside the original `/etc` dir.
So try not to use `/etc` dirs or other directories (e.g. don't use `environment.etc."code.py".source = ./code.py;`. Use the custom `copyToHome` option instead).

## Python-FHS compat env

As Python is expected to be the most common use case, it's already supported in the project.
A `compat-envs/python-fhs.nix` file fully defines the compatibility environment for most Python projects.
It also serves as an example for other projects.

Python FHS support greatly simplifies Python development and adds support for common commands like `pip install`.

You may modify and/or copy this file as needed.
If you get a missing dependencies error, add the needed dependency in the dependency list inside (see the note).
That might happen when using Python libraries with special dependencies.

As shown in `python-shared-venv` Python example, you can have venv in the persistent shared directory.
That's useful when rebuilding VMs and resetting all VM storage, as venv setup and package installation can take a long time.
This is a recommended approach if you expect VM config changes and reseting its storage, especially in developing configs.nix.

### Usage

To include the FHS environment in the VM, follow these steps (, see 'python-fhs-env' in the 'python' example):
1. add `(import ./compat-envs/python-fhs.nix { inherit pkgs; })` in `environment.systemPackages` (you may need to change the relative path or use an absolute path)
2. in `init.script` initialize and run the Python env:
    - initialize: `python-fhs -c 'init-python-venv -r requirements.txt'` (you may omit `-r requirements.txt`)
    - (if not using requirements.txt) run other setup commands like `python-fhs -c 'pip install numpy'`
    - run the wanted command inside the environment `python-fhs -c 'source venv/bin/activate && <your command here>'` (e.g., `python-fhs -c 'source venv/bin/activate && python code.py'`)

These same init.script commands can be run manually inside the VM.
In interactive VM shell, you can also enter the interactive python-fhs environment by using the name of the env (just run `python-fhs`).

# Shared directory

With `virtualisation.sharedDirectories` option, you can mount a host machine directory into a VM directory, creating a shared directory.

You can also use shared directories as persistent storage that persists even through configuration changes and VM storage deletions.
This is especially useful when creating VM config or generally when changes and storage deletions are frequent.

See `Python-FHS` and `python-shared-venv` for a complete example.

# Storage cleanup

To remove old, unused files from the nix store:
- optionally, first remove the result symlink if you wish to delete those files, too (all nix store files/dirs that have symlinks pointing to them won't be deleted)
- run the nix store garbage collector `nix store gc` (it may take few minutes to complete)
- old files, build results, and unused packages will be deleted


