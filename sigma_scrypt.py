import os
import sys
import subprocess
import getpass
from hashlib import scrypt


def print_usage():
    print("Usage:")
    print("")
    print(" To create a backup from a directory")
    print("     python script.py -c /path/to/directory")
    print("")
    print(" To restore from a backup")
    print("     python script.py -r /path/to/file.tar.gpg")


def readSalt() -> bytes:
    salt = b""

    try:
        with open(".salt", "rb") as saltFile:
            salt = saltFile.read()

        if salt is None or salt == "":
            raise Exception
    except Exception as e:
        print("[ERROR] Bad salt or salt not found")
        if input("Generate new salt (y|n): ") == "y":
            generateSalt()
        else:
            print("[ERROR] Wrong input, please try again, exiting...")
        sys.exit(1)

    return salt


def generateSalt():

    try:
        with open(".salt", "wb") as saltFile:
            saltFile.write(os.urandom(32))

        print(
            "[INFO]  New salt generated in .salt file, run the script again to use the new salt"
        )
        sys.exit(1)

    except Exception as e:
        print("[ERROR] failed to generate salt, reason:\n", e)
        sys.exit(1)


def deriveKey():
    try:
        passPhrase = ""
        passPhraseConfirm = ""

        while True:
            passPhrase = getpass.getpass("Enter Password: ")

            passPhraseConfirm = getpass.getpass("Confirm Password: ")

            if passPhrase != passPhraseConfirm:
                print(f"[ERROR] Passwords don't match...")
                del passPhrase
            else:
                break

        del passPhraseConfirm
    except Exception as e:
        print(f"[ERROR] Cannot get user password, reason\n", e)

    N = 2**16
    R = 8
    P = 2
    mem = N * P * R * 65

    return scrypt(password=passPhrase, salt=readSalt(), n=N, r=R, p=P, maxmem=mem).hex()


def encryptFile(tarFile):
    gpg_output_file = f"{tarFile}.gpg"

    key = deriveKey()

    return subprocess.run(
        [
            "gpg",
            "--no-symkey-cache",
            "--verbose",
            "-o",
            gpg_output_file,
            "--s2k-mode",
            "0",  # using hexadecimal key derived from password using scrypt
            "--symmetric",
            "--s2k-cipher-algo",
            "AES256",
            "--pinentry-mode",
            "loopback",
            "--passphrase",
            key,
            tarFile,
        ]
    ).returncode


def create_backup(selected_item):
    if not os.path.isdir(selected_item):
        print(f"[ERROR] Directory {selected_item} does not exist")
        sys.exit(1)

    print("[INFO] Creating tarball...")

    selected_folder = os.path.basename(selected_item)
    tarFile = f"{selected_folder}.tar"

    try:
        returnCode = subprocess.run(
            [
                "tar",
                "-cf",
                tarFile,
                "-C",
                os.path.dirname(selected_item),
                selected_folder,
            ],
            check=True,
        ).returncode

        if returnCode != 0:
            print(f"[ERROR] Could not create {tarFile}, exiting...")
            sys.exit(1)

        print("[INFO] Encrypting tarball...")

        if encryptFile(tarFile) == 0:
            print("[INFO]  Successfully created backup!")
        else:
            raise subprocess.CalledProcessError

    except subprocess.CalledProcessError as e:
        print("[ERROR] Failed to create backup, reason:\n", e)
        sys.exit(1)
    finally:
        print("[INFO] Cleaning up...")
        if os.path.exists(tarFile):
            os.remove(tarFile)


def restore_backup(selected_item):
    if not os.path.isfile(selected_item):
        print(f"[ERROR] File {selected_item} does not exist")
        sys.exit(1)

    tarFile = selected_item.rsplit(".", 1)[0]

    print("[INFO] Decrypting backup...")

    try:
        key = deriveKey()

        returnCode = subprocess.run(
            [
                "gpg",
                "-o",
                tarFile,
                "--decrypt",
                "--pinentry-mode",
                "loopback",
                "--passphrase",
                key,
                selected_item,
            ],
            check=True,
        ).returncode

        if returnCode == 0:
            print("[INFO]  Extracting from tarball...")

            if subprocess.run(["tar", "-xf", tarFile], check=True).returnCode == 0:
                print("[INFO] Successfully restored backup!")
            else:
                raise subprocess.CalledProcessError

    except subprocess.CalledProcessError as e:
        print("[ERROR] Failed to restore backup, reason:\n", e)
        sys.exit(1)
    finally:
        print("[INFO] Cleaning up...")
        if os.path.exists(tarFile):
            os.remove(tarFile)
        if os.path.exists(selected_item):
            os.remove(selected_item)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print_usage()
        sys.exit(1)

    option = sys.argv[1]
    selected_item = sys.argv[2]

    if option == "-c":
        create_backup(selected_item)
        # print(readSalt())
    elif option == "-r":
        restore_backup(selected_item)
    else:
        print_usage()
        sys.exit(1)
