
# Writing configurations

For each setup (combination of machines) write a single `configs.nix` file.
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

**Note**: this option doesn't work for disk images. Use hypervisor features to support this usecase.

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

You can use provided environment variables in this script.

NixOS (virtual) machine will start systemd service that runs the script and finishes or crashes with the script.
To see systemd service status run `systemctl status script-at-boot`.
If error happens or if you use echo inside the init script, run `journalctl -u script-at-boot` to show the full low.

Default: empty string, no special actions on boot.

Example:
```nix
init.script = ''
  echo "init script start"
  cp ~/my_log_out.txt ~/my_log_out.txt.old
  echo "the script started" > ~/my_log_out.txt
  echo "$MACHINE_TYPE" > ~/machine_type.txt
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

## diskImage

With this option you can configure what disk image will be generated.
Set the option to null to disable making a disk image for this machine/configuration.
Otherwise, set parameters for [make-disk-image.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix) (read all possible parameters and values in first curly braces `{ ... }`).

This option ignores count option meaning only one image per configuration will be built.
**Note**: the disk image won't be built unless appropriate built flag is used when building the configs.

If configuring this option (if it isn't null), the `format` parameter must be defined.

Default: `null`, disk images won't be generated.

Example:
```nix
diskImage = {
  format = "qcow2";
  additionalSpace = "512M";
  # any other make-disk-image.nix options
};
```

For full config example, see `disk-images` example.

## nixos-config

For everything else, use this option.
The `nixos-config` option lets you define whatever standard NixOS configurations you'd like.
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

**Warning**: don't define [virtualisation](https://search.nixos.org/options?sort=relevance&type=options&query=virtualisation) options here. See [nixos-config-virt](#nixos-config-virt) option. But if building only VMs (without the `diskImage` option or `--images` build argument) virtualisation options can be normally used in the `nixos-config`. But for consistency you can use nixos-config-virt.

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

Similarly, you can use `users.users.<name>.openssh.authorizedKeys.keyFiles` list to reference public key files, without inlining the keys as text in the config file.
Use absolute paths or paths relative to the current file where the path is written in.

Example:
```nix
nixos-config = {
  # ...
  users.users.nixy.openssh.authorizedKeys.keys = [
    # You probably want to generate your own SSH key and put it here. Don't use this one.
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5UeLggeVy8fX4dui4qGklKMbSTtKPfvDWE2ivoWxuGaCKkCyLKbNM+S/mzLUsHi2h9jCGNZOoXB3II8BNkIqwHImBeUgjE/tdP86Fy80+ZTrmwN2Cah7Gx5Oeqy0vcN3NKsAt0+Ey6XfFl8IdFPYQJ71jkDjcyVy/45isSgAwmhTP+guQwVUe9A5ZLXzu6pYYwQaTfyixEcxMiepOcCntE4L1CWHNiBwDmEGu+tN1yxEiz30wWsqpM/VLOM/XsohyQLQl/r5aEOfpjvg1Q8qNkN+RUkr9cnXoGntDz+AHb0bCt6Lvfv0FZuTFHWWQi8NKMLluedchDzOs4WeJs6fPmuGq339eEaKHluadGeFHHWormfMCwTMy+zPgdGGwF7ZOkjpw6QcCkEVmJrWLc4Qbqjnaie3lkqIq2DO6EF7sF+6fCk9FgvyvKz0dCAnqFnKfhyHOogcb+DnC79Tm90jScH4vUWvXXHaSjHcdTPw51n13InCXGFbZUFJrUcOElF2q08TL3n7vONThY+/J/FRSg0f/8ZKsC1Vmb9j0nVv0iF3fxCu9HfggTq+mLZCDxPEzxl89O11MuPHknps1Be6S0CDGO7lKf69anppjTs970T/jPCapxB4/FjZ+kdNzHtW84uaWiEQbzjdWisIrxETZAFCJ8le1lUtFCcdbWfh8Mw== ssh key for local nixos VMs"
  ];
  # or
  users.users.nixy.openssh.authorizedKeys.keys = [
    ../example_ssh_key.pub
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

## nixos-config-virt

This option similar to `nixos-config`, but is used only for virtual machines and is ignored when building a disk image.
Values from `nixos-config` and `nixos-config-virt` are combined for VM builds.

It's used mainly for any [virtualisation](https://search.nixos.org/options?sort=relevance&type=options&query=virtualisation) options because they cannot be defined in the `nixos-config` option.
It's required only for avoiding avoiding `virtualisation.` options' errors when building disk images.

**Note**: if building only VMs (without the `diskImage` option or `--images` build argument) virtualisation options can be normally used in the `nixos-config`. But for consistency you can use nixos-config-virt.

If you wish to overwrite value and ignore the original nixos-config value use `pkgs.lib.mkForce` (see examples below).

Default: `{}`, empty attribute set. No additional options.

Example:
```nix
nixos-config = {
  # Some options for both VM and disk image.
};
nixos-config-virt = {
  # Define virtualisation options, if you want
  virtualisation.memorySize = 1024;   # 1 GB RAM
  virtualisation.cores = 1;           # 1 CPU core
  virtualisation.sharedDirectories = {
    exampleSharedDir = {
      source = "/tmp/my-nixos-vms-shared/disk-images-example";
      target = "/mnt/shared";
    };
  };

  # Besides packages in nixos-config, also install lolcat in virtual machines
  environment.systemPackages = with pkgs; [ lolcat ];

  # Use pkgs.lib.mkForce to overwrite default value (intead of concatinating it)
  # This effectively deleted ssh key provided in nixos-config
  users.users.nixy.openssh.authorizedKeys.keys = pkgs.lib.mkForce [ ];
};
```

For full config example, see `disk-images` example.

The following are some standard NixOS virtualisation options that you might find useful.

### virtualisation.sharedDirectories

Mounts defined host machine directory into defined VM directory.
Multiple shared directories can be defined.
The contents of this directory are permanent and will remain on the host OS even after shutting down the VM.
This can be useful if you need permanent storage, while rebuilding and resetting VMs often.
It's also faster than `copyToHome` option and uses less storage.

**Important**: host machine directory needs to be created manually or VM will fail when you try to run it.

Example:
```nix
nixos-config-virt = {
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








