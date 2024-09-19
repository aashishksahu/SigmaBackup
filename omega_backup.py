import subprocess
import sys
import os

USAGE_MSG = '''
Usage:
  To create a backup from a directory
    python omega_backup.py -c /path/to/directory
  To restore from a backup
    python omega_backup.py -r /path/to/file.tar.g
'''


def log(msg, type):
  match type:
    case "E":
      print("[EROR] " + msg)
      sys.exit(1)
    case "W":
      print("[WARN] " + msg)
    case "I":
      print("[INFO] " + msg)


def is_gpg_available():
  try:
    subprocess.run(["gpg", "--help"], text=True, capture_output=True)
  except FileNotFoundError:
    log("gpg not found", "E")


def check_args(argv):
  if len(argv) != 3:
    log("Bad Arguments\n" + USAGE_MSG, "E")

  return (sys.argv[1], sys.argv[2])


def check_dir_exists(path):
  if not os.path.isdir(path):
    log("Folder not found", "E")


def check_file_exists(path):
  if not os.path.isfile(path):
    log("File not found", "E")


def create_backup(path):
  pass


def restore_backup(path):
  pass


if __name__ == "__main__":

  (action, path) = check_args(sys.argv)

  is_gpg_available()

  if action.lower() == "-c":
    check_dir_exists(path)
    create_backup(path)
  elif action.lower() == "-r":
    check_file_exists(path)
    restore_backup(path)
  else:
    print(USAGE_MSG)
