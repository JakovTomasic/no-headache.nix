import socket
import time
import subprocess
import ipaddress
from concurrent.futures import ThreadPoolExecutor, as_completed

# Dirty fix for knowing server IP address: constantly read it from the shared file.

PORT = 5000
TIMEOUT = 1
# Log to shared directory so I don't have to access client machine to read the log.
LOG_FILE = '/mnt/shared/client_log.txt'
SERVER_IP_FILE = '/mnt/shared/server_ip.txt'

server_ip = None

def log(text):
    with open(LOG_FILE, 'a') as f:
        f.write(text + "\n")


def get_ip_from_file():
    try:
        with open(SERVER_IP_FILE, "r") as f:
            ip = f.read().strip()
            return ip
    except FileNotFoundError:
        return None

# returns true if ip changed, false otherwise
def update_server_ip():
    global server_ip
    old = server_ip
    while True:
        server_ip = get_ip_from_file()
        if server_ip != None: return server_ip != old
        log("No devices found with port 5000 open. Trying again in 5 seconds...")
        time.sleep(5)

def main():
    global server_ip
    update_server_ip()

    while True:
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


if __name__ == "__main__":
    main()




