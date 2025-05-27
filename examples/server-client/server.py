import socket
import threading

HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 5000       # Port to listen on
LOG_FILE = '/home/nixy/log.txt'

def handle_client(conn, addr):
    print(f"Connected by {addr}")
    with conn:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            message = data.decode()
            print(f"Received from {addr}: {message}")
            with open(LOG_FILE, 'a') as f:
                f.write(f"{addr[0]}: {message}\n")

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"Server listening on {HOST}:{PORT}")
        while True:
            conn, addr = s.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()

