# password_lab
“Beginner-friendly password cracking lab using John the Ripper”
# Password Cracking Lab – Beginner Practice

## Purpose
This is a safe, beginner-friendly home lab for learning how password-cracking tools like John the Ripper work.  
All passwords used are **test/fake passwords** created for learning purposes.

## Lab Setup
- Environment: macOS with John the Ripper (jumbo version)
- Lab folder: `password_lab/`
- Files included:
  - `small_wordlist.txt` – small dictionary of common passwords.
  - `md5_hashes.txt` – MD5 hashes of test passwords.
  - `sha256_hashes.txt` – SHA256 hashes of test passwords.
  - `sha512crypt_hashes.txt` – salted SHA512 hashes of test passwords.

## Commands Used
```bash
# Crack MD5 hashes
john --wordlist=small_wordlist.txt --format=raw-md5 md5_hashes.txt

# Crack SHA256 hashes
john --wordlist=small_wordlist.txt --format=raw-sha256 sha256_hashes.txt

# Crack salted SHA512 hashes
john --wordlist=small_wordlist.txt --format=sha512crypt sha512crypt_hashes.txt

# Show results
john --show --format=Raw-MD5 md5_hashes.txt
john --show --format=Raw-SHA256 sha256_hashes.txt
john --show --format=sha512crypt sha512crypt_hashes.txt

