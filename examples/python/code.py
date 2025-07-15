import time
import numpy as np
import pandas as pd

LOG_FILE = '/mnt/shared/python-log.txt'

def test_pandas():
    df = pd.DataFrame({'a': range(3), 'b': range(3, 6)})
    return df.describe().to_string()

def main():
    # i = 0
    i = np.array(0) # A minor overcomplication, but this tests if numpy works
    while True:
        with open(LOG_FILE, 'a') as f:
            print(f"tick {i} (pandas test: ${test_pandas()})")
            f.write(f"tick {i} at ${time.ctime()} (pandas test: ${test_pandas()})\n")
        # close file to force flush
        i += 5
        time.sleep(5)

if __name__ == "__main__":
    main()

