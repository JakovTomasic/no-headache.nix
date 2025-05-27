import socket
import time
import subprocess

proc = subprocess.run(['tailscale', 'ip', '-4', 'server'], encoding='utf-8', stdout=subprocess.PIPE)
ip = proc.stdout

# SERVER_IP = '192.168.1.100'  # Replace with server's LAN IP
# SERVER_IP = '127.0.0.1'
SERVER_IP = ip.split('\n')[0]
PORT = 5000

def main():
    while True:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((SERVER_IP, PORT))
                while True:
                    message = f"Hello from client at {time.ctime()}"
                    s.sendall(message.encode())
                    print(f"Sent: {message}")
                    time.sleep(5)  # Send every 5 seconds
        except ConnectionRefusedError:
            print("Connection refused, retrying in 5 seconds...")
            time.sleep(5)

if __name__ == "__main__":
    main()

