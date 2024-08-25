#!/bin/bash

# Define the directory to be tarred
SELECTED_ITEM="$2"

# Selcted option: c - create backup, r - restore from backup
OPTION="$1"

if [ "$OPTION" != "-c" ] && [ "$OPTION" != "-r" ]; then
    echo "Usage:"
    echo ""
    echo " To create a backup from a directory"
    echo "     $0 -c /path/to/directory"
    echo ""
    echo " To restore from a backup"
    echo "     $0 -r /path/to/file.tar.g"
    exit 1
fi

# Check if the directory argument is provided
if [ -z "$SELECTED_ITEM" ]; then
    echo "Usage:"
    echo ""
    echo " To create a backup from a directory"
    echo "     $0 -c /path/to/directory"
    echo ""
    echo " To restore from a backup"
    echo "     $0 -r /path/to/file.tar.g"
    exit 1
fi


case "$OPTION" in
    "-c")
        # Check if the directory exists
        if [ ! -d "$SELECTED_ITEM" ]; then
            echo "[EROR] Directory $SELECTED_ITEM does not exist"
            exit 1
        fi

	echo "[INFO] Creating tarball..."
	
	# Define the output filename
        selected_folder=$(basename "$SELECTED_ITEM")
        TAR_FILE="${selected_folder}.tar"
        tar -cf "$TAR_FILE" -C "$(dirname "$SELECTED_ITEM")" "$(basename "$SELECTED_ITEM")"

        # Check if the command was successful
        if [ $? -eq 0 ]; then
            
            echo "[INFO] Encrypting tarball.."
            
            gpg --no-symkey-cache --verbose -o "$TAR_FILE.g" --s2k-mode 3 --s2k-digest-algo SHA512 --symmetric --s2k-cipher-algo AES256 "$TAR_FILE"
            
            if [ $? -eq 0 ]; then
            	echo "[INFO] Successfully created backup!"
            else
                echo "[EROR] Failed to encrypt backup"
            fi
            
            echo "[INFO] Cleaning up..."
            rm "$TAR_FILE"
        else
            echo "[EROR] Failed to create tarball"
            exit 1
        fi

        ;;

    "-r")
	# Check if the file exists
        if [ ! -f "$SELECTED_ITEM" ]; then
            echo "[EROR]  File $SELECTED_ITEM does not exist"
            exit 1
        fi
        
        TAR_FILE="${SELECTED_ITEM%.*}"

        echo "[INFO] Decrypting backup..."
	
	gpg -o "$TAR_FILE" --decrypt "$SELECTED_ITEM"
	
	if [ $? -eq 0 ]; then
	    echo "[INFO] Extracting from tarball"
	    
	    tar -xf "$TAR_FILE"
	    
	    # Check if the command was successful
            if [ $? -eq 0 ]; then
            	echo "[INFO] Successfully restored backup!"
            else
            	echo "[EROR] Failed to restore backup"
            fi
            
            echo "[INFO] Cleaning up..."
            rm "$TAR_FILE" "$SELECTED_ITEM"
	else
            echo "[EROR] Failed to decrypt backup"
            exit 1
        fi
        
        ;;

esac
