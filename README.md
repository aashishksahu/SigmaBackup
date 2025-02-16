# SigmaBackup

## sigma_gpg.sh
Uses only GPG to encrypt files using the SHA512 s2k key derivation and AES-256-CFB symmetric encryption
```
To create a backup from a directory
    sigma_backup.sh -c /path/to/directory"
To restore from a backup
    sigma_backup.sh -r /path/to/file.tar.gpg"
```

## sigma_age.sh
Uses [Age](https://github.com/FiloSottile/age) to encrypt files

[Format Specification](https://age-encryption.org/v1)
```
To create a backup from a directory
    sigma_age.sh -c /path/to/directory"
To restore from a backup
    sigma_age.sh -r /path/to/file.tar.age"
```


## page.ps1
Powershell alternative for sigma_age.sh
```
To create a backup from a directory
    page.ps1 -c /path/to/directory"
To restore from a backup
    page.ps1 -r /path/to/file.tar.age"
```
