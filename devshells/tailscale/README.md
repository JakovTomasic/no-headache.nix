
How to connect to tailscale:

For each terminal where you need sudo run `nix develop ./#tailscale` in the project root directory if you don't have tailscale installed globally on your system.

Run: `sudo tailscaled`

In new terminal, run `sudo tailscale up` and auth via brower or `sudo tailscale up --authkey=tskey-xxxxxxxxxxxxxxxx` if you want to use a key
- if ssh this isn't working try adding `--ssh` flag

Verify tailscale is running:
- `tailscale ip`
- `tailscale status`
- `ip a` should have tailscale0

Now you can use ssh to connect to other devices in the tailscale network
- note: be careful to use `ssh username@ip-address` and not hostname instead of username. The default username is nixy
- you can even connect via `ssh username@hostname`

When you're done, run:
```bash
sudo tailscale down
sudo pkill tailscaled
```

