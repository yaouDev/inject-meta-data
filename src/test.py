# ----------------------------------------------
IP Owner: yaouDev
Commit: c58060c0486b5a5274189472d7034713b7e7a490
Author: August J
Date: 2025-08-29T13:41:46+02:00
Message: reformat metadata string
----------------------------------------------
#

import os
import sys

def main():
  """
  Main function to run the application.
  """
  print("Hello, World! This is a simple test file.")
  print("This code doesn't do anything special, but it helps test a CI/CD pipeline.")

  print("\n--- Current System Information ---")
  print(f"Python Version: {sys.version}")
  print(f"Current Working Directory: {os.getcwd()}")
  print("----------------------------------")


if __name__ == "__main__":
  main()

