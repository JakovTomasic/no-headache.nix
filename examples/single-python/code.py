import time
import numpy as np

LOG_FILE = '/home/pythonguy/python-log.txt'

def main():
    # i = 0
    i = np.array(0) # A minor overcomplication, but this tests if numpy works
    while True:
        with open(LOG_FILE, 'a') as f:
            print(f"tick {i}")
            f.write(f"tick {i} at ${time.ctime()}\n")
        # close file to force flush
        i += 5
        time.sleep(5)

if __name__ == "__main__":
    main()

