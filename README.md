
todo: write instructions for what you do and how to recreate it

This is user documentation. For developer documentation see **TODO**.

**TODO** write user documentation
- update everything when api is well formed


# Setup

In `secrets/` directory cresate a file named `tailscale.authkey` (or change configuration to use different name and path)
- the file should just cointain the reusable tailscale key


# Basic run

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


# SSH

todo: not working

among other configs, in configuration.nix add
```nix
# This explicitly tells QEMU to forward localhost:10022 on the host to port 22 inside the guest VM
virtualisation.qemu.options = [
    "-nic" "user,hostfwd=tcp::10022-:22"
];
```

and run the VM. To check if it forwards run
```bash
grep -i 'hostfwd' ./result/bin/run-*-vm
# output should be: user,hostfwd=tcp::10022-:22 \
```

ssh into the vm by running on the host:
```bash
ssh root@localhost -p 10022
# todo: not working
```


# QEMU

before: `nix-shell -p libvirt`

list all VMs: `virsh list --all`
- todo: ne radi. Mozda jer je virsh u nix shell?
- or... `ps aux | grep qemu`
- or search "qemu" in mission center app


# VPN

todo: problematicno dodjeljivanje imena tailscale doda suffix `-1`, `-2`, itd ako dvaput upalis vm sa istim imenom (cak i ako prvo ugasis ovaj prije)

Use tailscale. You can even host your own server with headscale

todo: validate this
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



