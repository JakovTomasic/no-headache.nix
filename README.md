
TODO: project name? Naming is hard :(

# An overview

VM.Nix (TODO: project name) is a development and testing environment powered by the Nix package manager, allowing you to define and run declarative, reproducible, and isolated NixOS virtual machines (VMs) with minimal setup. It’s ideal for projects that require per-VM configuration, quick and easy VMs setup, or clean state environments, all without the overhead of containers or cloud infrastructure.

Key Features:

- Single config file per setup – define multiple VMs in a single `configs.nix`.
- Zero manual dependency management – all tools are provisioned through Nix.
- Built-in dev shell – provides commands for building, running, and managing VMs.
- Tailscale integration – connect VMs over VPN effortlessly.
- Persistent shared directories – share files between host and VM.
- Compatibility environments – supports complex setups (e.g., Python with FHS and pip install).
- SSH & port forwarding – connect to VMs via SSH from host or over VPN.
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

todo: the shorter the better. For other options then provide another sub-section in this setup section

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

## Enter the development shell

All commands and environment is available within the dev shell.
To enter the dev shell just run the `enterdevshell.sh` command (e.g. from the project's root directory run `./enterdevshell.sh`).

To exit the dev shell just close the terminal or run `exit`.


## Configurations

By convention, all VMs' configurations are contained in a single `configs.nix` file.

You can write custom `configs.nix` files (you can also change the file name) or use example configs provided in the `examples` directory.

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
Every time the VMs are built, the results symlink is overwritten with the new results.

Build outputs persist in the nix store even after you delete the result symlink. See [Storage cleanup](#storage-cleanup) section for how to remove old files.
That means you can have and use multiple results. E.g. you can:
- build VM from `configs1.nix`. The `results` symlink will be created
- rename it to results1 so it doesn't get overwritten (run `mv results results1`)
- build VM again, but use `configs2.nix`
- optionally, rename new results, too. For consistency (`mv results results2`)
- you now have two results symlink directories. Each for separate configs.

### Running VMs

There are few ways to run VMs from built configurations.

Generally, by running a VM a image for persistent storage `name_of_the_machine.qcow2` will be created in the current directory.
For simple configs, the image is just around 10 MB big because `/nix/store` is shared with the host.

**Delete qcow2 file** when you change the configuration (before running the VM with different configuration).
*Note*: commands for running VMs will print warning and remind you if you forget to remove qcow2 file.

Default username for the VM is `nixy` and the password is `nixos`, unless changed in your `configs.nix`.

### Run individual VM

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

Running `runAllVms` runs all VMs from the last built `configs.nix`.

All arguments'll be forwarded to script for running each individual VM. See [Run individual vm](#run-individual-vm) to see options.


## SSH

When using SSH in a VPN use it normally.
OpenSSH server is enabled by default.

To SSH into VM from your host machine without using VPN a port forwarding rule needs to be set to forward SSH connection from localhost to VM you want.
That's supported in the configs file.
Full example of such `configs.nix` is provided in the `ssh-from-host` example.

Just define the `firstHostSshPort` option (e.g. set it to 2222) and build and run the VMs.

When a VM is running you can SSH into it by running appropriate command in the generated `results/bin/` directory.
For example, run `./result/bin/ssh-into-yourVmName`.

If you get error: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!" delete that known host from `~/.ssh/known_hosts` (you probably want to delete all hosts that begin with `[localhost]:some-port` there). That error shouldn't happen if using only the `./result/bin/ssh-into-yourVmName` scripts.


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

To remove old unused files from the nix store:
- optionally, first remove the results symlink if you wish to delete those files, too
- run nix store garbage collector `nix store gc` (it may take few minutes to complete)
- old files, build results and unused packages will be deleted

# Writing configurations

todo - how to write configs.nix - maybe put this in another file, just for configurations

For each setup (combination of virtual machines) write a single `configs.nix` file.
The configuration is managed in nix programming language.
See [Nix language basics](https://nix.dev/tutorials/nix-language) to familiarize yourself with the syntax.
Or just read the examples and figure stuff out on the way.

For concrete examples read `configs.nix` files inside `examples/` directory.

Template for each `configs.nix` files is as follows:

```nix
{ pkgs, ... }:
let
  # you can define variables here for code deduplication inside this file.
in
{
  # change vmName to any name you'd like
  vmName = {
    # VM config options go here
  };

  # optionally, you can define as many VM types as you'd like
  secondVm = {
    # config options for the second VM go here
  };
}
```

Here's the breakdown:
- inside `let ... in` you can define global variable within the file. You can use that for shared constants, code deduplication or other.
- after `let ... in` there is an attribute set `{ ... }`. An attribute set is a collection of name-value-pairs, where names must be unique (like an object in JSON, see example and comparison [here](https://nix.dev/tutorials/nix-language#attribute-set)).
- each key inside that attribute set is a name of a VM configuration with value being its configuration (another attribute set).
- VM configuration contains options specific only to that configuration. Those are explained below.


## username

Defines name of the VM user. Used for logging-in and defining a home directory path (`/home/username/`).

Default: `"nixy"`

Example:
```nix
username = "john";
```

## tailscaleAuthKeyFile

A path to a file with Tailscale auth key (and nothing else), relative to the path of the current `configs.nix` file or absolute path. Providing null means Tealscale is disabled.
If valid file is provided, Tailscale will automatically be initialized.

Default: `null`, tailscale is disabled

Example:
```nix
tailscaleAuthKeyFile = ./secrets/tailscale.authkey;
```

For full config example, see `?` example.
- todo: write tailscale example?

## count

A positive number defining how many instances of that VM to create, with the same configuration.
You can set count to 0 to disable that configuration, like it wasn't defined.

Default: `1`, create a single instance

Example:
```nix
count = 2;
```

For full config example, see `vm-count-option` example.

## firstHostSshPort

Used for enabling SSH from the host machine, as explained in the README.
If null, host cannot connect to the VM without VPN. This defines the first SSH port for this VM type. If count option is greather than one then each instance will have the next number as its SSH port. No two VM instances can have the same port.

Default: `null`, SSH from the host machine isn't possible

Example:
```nix
firstHostSshPort = 2300;
```

For full config example, see `ssh-from-host` example.

## init.script

A (multiline) string defining bash script to run when VM starts.
It'll run in the background and you don't have to login into the VM user to start it.
The script is run as the user.
This is useful options for automatins scripts.

NixOS virtual machine will start systemd service that runs the script and finishes or crashes with the script.
To see systemd service status run `systemctl status script-at-boot`.
If error happens or if you use echo inside the init script, run `journalctl -u script-at-boot` to show the full low.

Default: empty string, no special actions on boot.

Example:
```nix
init.script = ''
  echo "init script start"
  cp ~/my_log_out.txt ~/my_log_out.txt.old
  echo "the script started" > ~/my_log_out.txt
'';
```

## copyToHome

Copies files and directories from host machine to desired location in the VM, relative to user home directory.
To be precise, this option copies the files to the shared nix store and in VM creates symlinks to the files in the nix store.
That means **the files/dirs are read-only**. To modify the files just copy them in the VM (e.g. you can add in your init.script `cp code.py code2.py` where code.py is symlink to a read-only file and code2.py will be created as a normal read/write file).
In the attr set, left (key) is destination string path (in quotes) in the VM relative to the VM home directory, right (value) is a path (without quotes) relative to the `configs.nix` file in which the path is written or absolute path. There may be any number of files or directories.

Alternatively, you may want to use shared directory option instead of copying content.

Default: `{}`, empty attribute set. No files or directories will be copied.

Example:
```nix
copyToHome = {
  "code.py" = ./python/code.py;
  "config/settings.json" = /etc/second-file-path/settings.json;
};
```

For full config example, see `copy-to-home` example.

## nixos-config

For everything else, use this option.
The `nixos-config` option lets you define whatever standard NixOS configurations you'd like, including NixOS options for virtual machines (see [virtualisation.](https://search.nixos.org/options?from=0&size=50&sort=relevance&type=packages&query=virtualisation.) options).
You can search all NixOS options [here](https://search.nixos.org/options).
The value of the option is attribute set with same syntax and options as standard NixOS configuration.nix file.

Note that there is default NixOS configuration located in `devshells/main/base-configuration.nix` file.
These `nixos-config` options overwrite or extend the ones defined there in the `base-configuration.nix` file.
Don't change that file unless you know what you're doing (read [dev doc](./doc/dev.md) first).

Default: `{}`, empty attribute set. No additional options.

Example:
```nix
nixos-config = {
  # Define NixOS options here, like in configuration.nix

  # E.g. define list of packages to install. Install python3 and vim:
  environment.systemPackages = with pkgs; [ python3 vim ];
};
```

The following options are some standard NixOS options that you might find useful.

Note: to configure these programs e.g. to automatically start and run in the background you'll have to configure them directly in the NixOS config.
For example, to turn on OpenSSH add `services.openssh.enable = true;` to the configuration (this is enabled by default for this project).

### environment.systemPackages

Defines a list of packages (programs) to install in the VM.
You can search for all packages [here](https://search.nixos.org/packages).

Example:
```nix
nixos-config = {
  # ...
  # install these packages in the VM (note: in nix lists there is not comma separator):
  environment.systemPackages = with pkgs; [
    git
    vim
    zip
    unzip
  ];
};
```

### virtualisation.sharedDirectories

Mounts defined host machine directory into defined VM directory.
Multiple shared directories can be defined.
The contents of this directory are permanent and will remain on the host OS even after shutting down the VM.
This can be useful if you need permanent storage, while rebuilding and resetting VMs often.
It's also faster than `copyToHome` option and uses less storage.

**Important**: host machine directory needs to be created manually or VM will fail when you try to run it.

Example:
```nix
nixos-config = {
  # ...
  virtualisation.sharedDirectories = {
    # Any name. Multiple shared directories can be here.
    exampleSharedDir = {
      # Absolute path to host OS path of dir to be shared
      # Important: you need to create this directory before starting this VM
      # use: mkdir -p /tmp/my-nixos-vms-shared/shared-dir-example
      source = "/tmp/my-nixos-vms-shared/shared-dir-example";
      # Absolute path to virtual machine path
      target = "/mnt/shared";
    };
  };
};
```

For full config example, see `shared-dir` example.

### Disable OpenSSH

OpenSSH is turned on by default, as it'll be common usecase and I prefer to SSH into a VM instead of accessing it directly through window.

To disable OpenSSH in a VM add this option:
```nix
nixos-config = {
  # ...
  services.openssh.enable = false;
};
```

### SSH public key

To add public SSH key to your VM generate it and put it in the `users.users.<your username>.openssh.authorizedKeys.keys` list.
While doing this you also may or may not want to disable OpenSSH password authentication to force authentication only with the key.

Example:
```nix
nixos-config = {
  # ...
  users.users.nixy.openssh.authorizedKeys.keys = [
    # You probably want to generate your own SSH key and put it here. Don't use this one.
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
  ];
  # Uncomment if you want this (the default is true):
  # services.openssh.settings.PasswordAuthentication = true;
};
```

### networking.firewall.allowedTCPPorts

To open VM's TCP ports define list if ports as follows (nix lists don't have comma separator):
```nix
nixos-config = {
  # ...
  networking.firewall.allowedTCPPorts = [ 5000 5001 ];
};
```

For full config example, see `server-client` example.

### And much, much more

You'll never learn all of the options.
Search options [here](https://search.nixos.org/options).
Also consult the official [NixOS wiki](https://wiki.nixos.org/).








