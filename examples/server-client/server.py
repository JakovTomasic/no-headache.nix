import socket
import threading

HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 5000       # Port to listen on
# Log to shared directory so I don't have to access server machine to read the log.
LOG_FILE = '/mnt/shared/server_log.txt'

def log(text):
    with open(LOG_FILE, 'a') as f:
        f.write(text + "\n")

log(f"successful init {LOG_FILE}, {PORT}")

def handle_client(conn, addr):
    with conn:
        while True:
            data = conn.recv(1024)
            if not data:
                break
            message = data.decode()
            log(f"Received from {addr[0]}: {message}")

def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        log(f"Server listening on {HOST}:{PORT}")
        while True:
            conn, addr = s.accept()
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()

