# # ----------------------------------------------
# IP Owner: yaouDev
# Commit: b27589051bc0badc21fc4a64de54e67a89ab0e2a
# Author: August J
# Date: 2025-08-29T13:51:40+02:00
# Message: add comments to metadata injection
# ----------------------------------------------


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

