#!/bin/bash

# Define the directory to be tarred
$SELECTED_ITEM = $args[1]

# Selcted option: c - create backup, r - restore from backup
$OPTION = $args[0]

if ($OPTION -ne "-c" -and $OPTION -ne "-r") {
    "Usage:"
    ""
    " To create a backup from a directory"
    "     page.ps1 -c /path/to/directory"
    ""
    " To restore from a backup"
    "     page.ps1 -r /path/to/file.tar.age"
    Exit 1
}

# Check if the directory argument is provided
if ([string]::IsNullOrEmpty($SELECTED_ITEM)) {
    "Usage:"
    ""
    " To create a backup from a directory"
    "     page.ps1 -c /path/to/directory"
    ""
    " To restore from a backup"
    "     page.ps1 -r /path/to/file.tar.age"
    Exit 1
}


switch ($OPTION) {
    "-c" {
        # Check if the directory exists
        if (!(Test-Path -Path $SELECTED_ITEM -PathType Container)) {
            "[EROR] Directory $SELECTED_ITEM does not exist"
            Exit 1
        }
    

        "[INFO] Creating tarball..."
	
        # Define the output filename
        $selected_folder = Split-Path -Path $SELECTED_ITEM -Leaf
        $parent_folder = Split-Path -Path $SELECTED_ITEM -Parent
        
        $TAR_FILE = "${selected_folder}.tar"
        
        tar -cf "$TAR_FILE" -C "$parent_folder" "$selected_folder"

        # Check if the command was successful
        if ($?) {
            
            "[INFO] Encrypting tarball.."
            
            age --passphrase  --output "$TAR_FILE.age" "$TAR_FILE"

            if ( $?) {
                "[INFO] Successfully created backup!"
            }
            else {
                "[EROR] Failed to encrypt backup"            
            }
            "[INFO] Cleaning up..."
            Remove-Item "$TAR_FILE"
        }
        else {
            "[EROR] Failed to create tarball"
            Exit 1
        }
        
    }

    "-r" {
        # Check if the file exists
        if (!(Test-Path -Path $SELECTED_ITEM -PathType Leaf)) {
            "[EROR]  File $SELECTED_ITEM does not exist"
            Exit 1
        }
        
        $TAR_FILE = [System.IO.Path]::GetFileNameWithoutExtension($SELECTED_ITEM)

        "[INFO] Decrypting backup..."
	
        age --decrypt --output "$TAR_FILE" "$SELECTED_ITEM"

        if ($?) {
            "[INFO] Extracting from tarball"
	    
            tar -xf "$TAR_FILE"
	    
            # Check if the command was successful
            if ( $?) {
                "[INFO] Successfully restored backup!"
            }
            else {
                "[EROR] Failed to restore backup"
            }
            
            "[INFO] Cleaning up..."
            Remove-Item "$TAR_FILE"
            Remove-Item "$SELECTED_ITEM"
        }
        else {
            "[EROR] Failed to decrypt backup"
            Exit 1
        }
    }
}

