#!/usr/bin/env bash
# mac_password_cracking_lab.sh
# Beginner password-cracking lab for macOS (safe, offline, educational)
# WHAT IT DOES:
#  - checks/installs john and hashcat via Homebrew (asks before installing)
#  - creates a sample passwords.txt
#  - generates MD5 and SHA256 hash files (one-hash-per-line)
#  - generates shadow-like salted SHA512-crypt hashes using Python's crypt
#  - shows recommended John/Hashcat commands to run (asks before executing)
#  - provides a small printable worksheet at the end (printed to console)
# SAFETY: This script only creates hashes for passwords YOU create here. It will
# never touch /etc/shadow or any system password file.

set -euo pipefail
IFS=$'\n\t'

# --- helper functions ---
confirm(){
  # yes/no prompt
  while true; do
    read -rp "$1 [y/n]: " yn
    case "$yn" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

command_exists(){ command -v "$1" >/dev/null 2>&1; }

report(){ echo -e "\n==> $1"; }

# --- 0. macOS sanity check ---
report "macOS lab script starting. This is safe and offline."
if [[ $(uname) != "Darwin" ]]; then
  echo "Warning: this script was written for macOS. You are not on macOS (uname=$(uname)). Continue?"
  if ! confirm "Continue on non-macOS?"; then
    echo "Aborting."; exit 1
  fi
fi

# --- 1. Homebrew and tools ---
BREW_CMD=""
if ! command_exists brew; then
  echo "Homebrew not found. The script can install john and hashcat with Homebrew,"
  echo "but Homebrew itself must be installed manually first (see https://brew.sh)."
  if confirm "Would you like to continue and install Homebrew now? (This will open the Homebrew install)"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  else
    echo "Please install Homebrew or manually install john/hashcat, then re-run this script."; exit 1
  fi
fi

# refresh brew
report "Updating Homebrew..."
brew update || true

# install john and hashcat
if ! command_exists john; then
  if confirm "Install John the Ripper (john) via Homebrew?"; then
    brew install john
  else
    echo "You chose not to install john. Some parts of the lab will be skipped.";
  fi
fi

if ! command_exists hashcat; then
  if confirm "Install Hashcat via Homebrew? (Recommended for mask attacks)"; then
    brew install hashcat
  else
    echo "You chose not to install hashcat. Hashcat-specific exercises will be skipped.";
  fi
fi

# ensure python3 exists
if ! command_exists python3; then
  echo "Python3 not found. Installing python..."
  brew install python
fi

# create workspace
WORKDIR="$HOME/password_lab"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
report "Working directory: $WORKDIR"

# --- 2. Create a sample passwords list ---
PWFILE="passwords.txt"
if [[ -f "$PWFILE" ]]; then
  echo "$PWFILE already exists in $WORKDIR"
  if confirm "Overwrite existing $PWFILE?"; then
    rm -f "$PWFILE"
  else
    echo "Keeping existing file.";
  fi
fi

cat > "$PWFILE" <<'EOF'
password123
letmein
Tr0ub4dor!
S3cureP@ssw0rd
12345678
admin2020
Summer2021
MyPuppy!
P@ssw0rd!
qwerty
EOF

report "Created sample password list: $WORKDIR/$PWFILE"

# --- 3. Generate unsalted MD5 and SHA256 hash files (one-hash-per-line) ---
MD5FILE="md5_hashes.txt"
SHA256FILE="sha256_hashes.txt"

# create MD5
> "$MD5FILE"
while IFS= read -r p; do
  # echo -n preserves no newline
  printf "%s\n" "$(printf "%s" "$p" | md5 -q)" >> "$MD5FILE"
done < "$PWFILE"

# create SHA256
> "$SHA256FILE"
while IFS= read -r p; do
  printf "%s\n" "$(printf "%s" "$p" | shasum -a 256 | awk '{print $1}')" >> "$SHA256FILE"
done < "$PWFILE"

report "Generated hash files: $MD5FILE, $SHA256FILE"

# --- 4. Generate shadow-like salted SHA512-crypt hashes using Python crypt ---
SHADOWFILE="sha512crypt_hashes.txt"
> "$SHADOWFILE"
python3 - <<'PY'
import crypt, random, string
pwfile = 'passwords.txt'
out = 'sha512crypt_hashes.txt'
with open(pwfile,'r') as f, open(out,'w') as o:
    for line in f:
        pw = line.rstrip('\n')
        if not pw: continue
        salt = '$6$' + ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8))
        h = crypt.crypt(pw, salt)
        # write in a simple format: username:hash (john can read common shadow formats)
        o.write('user:'+h+'\n')
print('Wrote', out)
PY

report "Generated salted SHA512-crypt (shadow-like) hashes: $SHADOWFILE"

# --- 5. Small local wordlist (copy of top entries for safe offline testing) ---
LOCALWL="small_wordlist.txt"
cat > "$LOCALWL" <<'EOF'
password
123456
12345678
qwerty
abc123
password1
iloveyou
admin
welcome
monkey
EOF
report "Created small local wordlist: $LOCALWL"

# --- 6. Show recommended John commands and offer to run them ---
report "Recommended John commands (won't run automatically unless you allow):"
cat <<'CMDS'
# 1) Crack MD5 (raw-md5) using small wordlist:
john --wordlist=small_wordlist.txt --format=raw-md5 md5_hashes.txt

# 2) Crack SHA256 (raw-sha256) using small wordlist:
john --wordlist=small_wordlist.txt --format=raw-sha256 sha256_hashes.txt

# 3) Use rules to extend guesses (rockyou is better if you have it):
john --wordlist=small_wordlist.txt --rules --format=raw-sha256 sha256_hashes.txt

# 4) Crack sha512crypt (shadow-like) hashes:
john --format=sha512crypt sha512crypt_hashes.txt

# 5) Show cracked results:
john --show <file>
CMDS

if command_exists john; then
  if confirm "Run the three john jobs above now? (md5, sha256, sha512crypt)"; then
    echo "Running john (this may take a moment)..."
    # run md5
    if [[ -s "$MD5FILE" ]]; then
      john --wordlist="$LOCALWL" --format=raw-md5 "$MD5FILE" || true
    fi
    # run sha256
    if [[ -s "$SHA256FILE" ]]; then
      john --wordlist="$LOCALWL" --format=raw-sha256 "$SHA256FILE" || true
    fi
    # run sha512crypt
    if [[ -s "$SHADOWFILE" ]]; then
      john --format=sha512crypt "$SHADOWFILE" || true
    fi
    report "John run finished. Use 'john --show <file>' to view cracked passwords."
  else
    echo "Skipping automatic john run. You can run the commands shown above when ready.";
  fi
else
  echo "john not installed; cannot run john automatically.";
fi

# --- 7. Hashcat examples ---
if command_exists hashcat; then
  report "Hashcat examples (you must run these manually or allow execution):"
  cat <<'HC'
# Hashcat dictionary attack on raw SHA256 (mode 1400):
# hashcat -m 1400 -a 0 sha256_hashes.txt small_wordlist.txt

# Hashcat mask attack example (try 8-character lower+digits mask):
# hashcat -m 1400 -a 3 sha256_hashes.txt ?l?l?l?l?l?l?d?d

# Show cracked (hashcat --show):
# hashcat -m 1400 --show sha256_hashes.txt
HC
  if confirm "Run a quick Hashcat dictionary attack on sha256_hashes.txt using the small wordlist?"; then
    echo "Running hashcat dictionary attack (may be slower on CPU)..."
    # run with -w 1 (workload) and --potfile-disable to avoid persistent potfile if user prefers
    hashcat -m 1400 -a 0 "$SHA256FILE" "$LOCALWL" --potfile-path="$WORKDIR/hashcat.pot" || true
    report "Hashcat run finished. Use 'hashcat --show <file>' to view cracked results."
  else
    echo "Skipping hashcat automatic run.";
  fi
else
  echo "hashcat not installed; skipping hashcat examples.";
fi

# --- 8. Printable worksheet (console output) ---
report "LAB WORKSHEET: copy these answers into a notebook or save to a file."
cat <<'WS'
================ PASSWORD CRACKING LAB WORKSHEET ================
Lab date: ____________________

Files created (location: $WORKDIR):
 - passwords.txt (your test plaintext passwords)
 - md5_hashes.txt (unsalted MD5, one hash/line)
 - sha256_hashes.txt (SHA-256, one hash/line)
 - sha512crypt_hashes.txt (shadow-like salted SHA512 entries)
 - small_wordlist.txt (small local wordlist for testing)

Exercise 1: Dictionary attack with John
 - Command used: ___________________________________________
 - Which hashes were cracked? _______________________________
 - Example cracked (hash -> password): _______________________
 - Time taken (approx): ___________________________________

Exercise 2: Rules & Masks
 - Command used: ___________________________________________
 - Which additional passwords cracked? _______________________
 - Patterns observed (e.g., 'password with digit at end'): _______________

Exercise 3: Salted hashes
 - Command used: ___________________________________________
 - Were any salted hashes cracked? Yes / No
 - Notes: _________________________________________________

Defensive lessons learned:
 - What made passwords weak? _______________________________
 - What would you recommend to users/administrators? _________

Notes / next steps:
 - Try adding rockyou.txt and rerun with --rules
 - Try creating longer/random passwords and verify they are not cracked

================================================================
WS

report "Script finished. Files are in $WORKDIR"

echo "Helpful next steps:"
echo " - If you want rockyou.txt, download it manually from a trusted mirror and place it in $WORKDIR (or use a curated wordlist)."
echo " - To inspect results of john runs: john --show <file>"
echo " - To remove all files created by this lab: rm -rf $WORKDIR (only if you are sure)"

# End of script
