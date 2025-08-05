
# Server-client example

Example of two virtual machines that have one server (receiver) and one client (publisher).
They log their activity.

They communicate over tailscale network.

Example usecase:
- open client - it'll wait for the server
- open server - they'll start to communicate
- close the server - client will wait
- open new server - client will reconnect to the new server


