# __GIT_COMMIT_METADATA__

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

