# SigmaBackup

## sigma_gpg.sh
Uses only GPG to encrypt files using the SHA512 s2k key derivation and AES-256-CFB symmetric encryption
```
To create a backup from a directory
    sigma_backup.sh -c /path/to/directory"
To restore from a backup
    sigma_backup.sh -r /path/to/file.tar.gpg"
```

## sigma_scrypt.py
Uses Scrypt KDF to derive a key and use that key to encrypt files using GPG with AES-256-CFB symmetric encryption
```
To create a backup from a directory
    python sigma_scrypt.py -c /path/to/directory"
To restore from a backup
    python sigma_scrypt.py -r /path/to/file.tar.gpg"
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
