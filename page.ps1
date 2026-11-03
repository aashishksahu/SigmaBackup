# Usage:
#   backup.ps1 -c C:\path\to\directory     create encrypted backup (folder.7z.age)
#   backup.ps1 -r C:\path\to\folder.7z.age restore from backup

$OPTION        = $args[0]
$SELECTED_ITEM = $args[1]

function Show-Usage {
    "Usage:"
    ""
    " To create a backup from a directory"
    "     backup.ps1 -c C:\path\to\directory"
    ""
    " To restore from a backup"
    "     backup.ps1 -r C:\path\to\file.7z.age"
    Exit 1
}

if ($OPTION -ne "-c" -and $OPTION -ne "-r") { Show-Usage }
if ([string]::IsNullOrEmpty($SELECTED_ITEM)) { Show-Usage }

# Locate 7z
$7z = (Get-Command 7z -ErrorAction SilentlyContinue).Source
if (-not $7z) { $7z = "C:\Program Files\7-Zip\7z.exe" }
if (-not (Test-Path $7z)) { "[EROR] 7z not found. Install with: winget install 7zip.7zip"; Exit 1 }
if (-not (Get-Command age -ErrorAction SilentlyContinue)) { "[EROR] age not found in PATH"; Exit 1 }

# Least-fragile 7z settings:
#   -t7z      standard 7z container
#   -mx=0     store only, no compression (use -mx=1 for light compression)
#   -ms=off   NON-solid: damage to one spot only affects that file, not everything after it
#   -mhe off  no 7z encryption (age does the encryption)
#   -bsp1     show progress percentage
$SEVENZ_ARGS = @("-t7z", "-mx=0", "-ms=off", "-bsp1", "-bb0")

switch ($OPTION) {
    "-c" {
        if (!(Test-Path -Path $SELECTED_ITEM -PathType Container)) {
            "[EROR] Directory $SELECTED_ITEM does not exist"
            Exit 1
        }

        $full            = (Resolve-Path $SELECTED_ITEM).Path.TrimEnd('\')
        $selected_folder = Split-Path -Path $full -Leaf
        $parent_folder   = Split-Path -Path $full -Parent
        $ARCHIVE         = Join-Path (Get-Location).Path "${selected_folder}.7z"

        if (Test-Path $ARCHIVE) { Remove-Item $ARCHIVE }   # 7z would otherwise append to it

        "[INFO] Creating archive..."
        $code = $null
        Push-Location $parent_folder
        try {
            & $7z a @SEVENZ_ARGS "$ARCHIVE" "$selected_folder"
            $code = $LASTEXITCODE
        }
        finally {
            # Always return to the original directory, even if interrupted with Ctrl+C
            Pop-Location
            # $code is still $null only if we were interrupted: remove the partial archive
            if ($null -eq $code -and (Test-Path $ARCHIVE)) {
                Remove-Item $ARCHIVE -ErrorAction SilentlyContinue
            }
        }

        # 7z exit codes: 0 = ok, 1 = warning (some files skipped/locked), 2+ = fatal
        if ($code -ne 0) {
            "[EROR] 7z reported problems (exit code $code). Some files may be missing. Aborting."
            if (Test-Path $ARCHIVE) { Remove-Item $ARCHIVE }
            Exit 1
        }

        "[INFO] Verifying archive integrity..."
        & $7z t "$ARCHIVE" -bsp1 -bb0
        if ($LASTEXITCODE -ne 0) {
            "[EROR] Archive failed integrity test. Aborting."
            Remove-Item $ARCHIVE
            Exit 1
        }

        "[INFO] Encrypting archive..."
        age --passphrase --output "$ARCHIVE.age" "$ARCHIVE"

        if ($LASTEXITCODE -eq 0) {
            "[INFO] Successfully created backup: $ARCHIVE.age"
            "[INFO] Cleaning up..."
            Remove-Item "$ARCHIVE"
        }
        else {
            "[EROR] Failed to encrypt backup"
            if (Test-Path "$ARCHIVE.age") { Remove-Item "$ARCHIVE.age" }   # remove partial output
            Remove-Item "$ARCHIVE"
            Exit 1
        }
    }

    "-r" {
        if (!(Test-Path -Path $SELECTED_ITEM -PathType Leaf)) {
            "[EROR] File $SELECTED_ITEM does not exist"
            Exit 1
        }

        $ARCHIVE = Join-Path (Get-Location).Path ([System.IO.Path]::GetFileNameWithoutExtension($SELECTED_ITEM))

        "[INFO] Decrypting backup..."
        age --decrypt --output "$ARCHIVE" "$SELECTED_ITEM"

        if ($LASTEXITCODE -ne 0) {
            "[EROR] Failed to decrypt backup"
            if (Test-Path "$ARCHIVE") { Remove-Item "$ARCHIVE" }
            Exit 1
        }

        "[INFO] Verifying archive integrity..."
        & $7z t "$ARCHIVE" -bsp1 -bb0
        if ($LASTEXITCODE -ne 0) {
            "[EROR] Archive failed integrity test. Keeping decrypted archive for inspection: $ARCHIVE"
            Exit 1
        }

        "[INFO] Extracting archive..."
        & $7z x "$ARCHIVE" "-o$((Get-Location).Path)" -bsp1 -bb0 -y

        if ($LASTEXITCODE -eq 0) {
            "[INFO] Successfully restored backup!"
            "[INFO] Cleaning up..."
            Remove-Item "$ARCHIVE"
            # The encrypted .age file is intentionally NOT deleted.
        }
        else {
            "[EROR] Failed to restore backup (exit code $LASTEXITCODE). Keeping $ARCHIVE"
            Exit 1
        }
    }
}
