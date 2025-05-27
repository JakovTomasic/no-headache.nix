import time

LOG_FILE = '/home/nixy/python-log.txt'

def main():
    i = 0
    while True:
        with open(LOG_FILE, 'a') as f:
            print(f"tick {i}")
            f.write(f"tick {i} at ${time.ctime()}\n")
        # close file to force flush
        i += 5
        time.sleep(5)

if __name__ == "__main__":
    main()

