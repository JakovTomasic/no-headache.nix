
todo: write instructions for what you do and how to recreate it

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

```
Running the virtual machine will create a `nixos.qcow2` file in the current directory. **Delete this file** when you change the configuration.


# SSH

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


