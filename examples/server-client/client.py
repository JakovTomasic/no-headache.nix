import socket
import time
import subprocess
import json
import re

# The scripts finds ip address from tailscale using command 'tailscale status --json'

PORT = 5000
TIMEOUT = 1
# Log to shared directory so I don't have to access client machine to read the log.
LOG_FILE = '/mnt/shared/client_log.txt'

server_ip = None

def log(text):
    with open(LOG_FILE, 'a') as f:
        f.write(text + "\n")


def get_server_ip():
    try:
        # Run `tailscale status --json` and capture the output
        result = subprocess.run(['tailscale', 'status', '--json'], capture_output=True, text=True, check=True)
        status = json.loads(result.stdout)

        # The 'Peer' key contains all the connected devices
        peers = status.get("Peer", {}) if isinstance(status, dict) else {}


        for peer in peers.values():
            # Match a device with a name like 'server-<index>'
            hostname = peer.get("HostName", "")
            is_online = peer.get("Online", False)
            if hostname == "server" and is_online:
                # Return the first available IP address
                ips = peer.get("TailscaleIPs", [])
                if ips:
                    return ips[0]

        return None  # No matching server found

    except subprocess.CalledProcessError as e:
        log("Error running tailscale status")
    except json.JSONDecodeError:
        log("Failed to parse JSON from tailscale status")
    return None

# returns true if ip changed, false otherwise
def update_server_ip():
    global server_ip
    old = server_ip
    while True:
        server_ip = get_server_ip()
        if server_ip != None: return server_ip != old
        log("No devices found with port 5000 open. Trying again in 5 seconds...")
        time.sleep(5)

def main():
    global server_ip

    while True:
        update_server_ip()
        log(f"Server IP found: {server_ip}")
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((server_ip, PORT))
                while True:
                    message = f"Hello from client at {time.ctime()}"
                    s.sendall(message.encode())
                    log(f"Sent: {message}")
                    time.sleep(5)  # Send every 5 seconds
                    if update_server_ip():
                        log(f"Server IP address changed! New ip = {server_ip}")
                        break
        except ConnectionRefusedError:
            log("Connection refused, retrying in 5 seconds...")
            time.sleep(5)
        except ConnectionResetError:
            log("Connection reset, retrying in 5 seconds...")
            time.sleep(5)


if __name__ == "__main__":
    main()




