#!/usr/bin/env bash
set -euo pipefail

name="${GPG_NAME:-VPINOS Debian Repository}"
email="${GPG_EMAIL:-superhac007@gmail.com}"
home="${GNUPGHOME:-$PWD/.gnupg-vpinos}"
public_key_path="${PUBLIC_KEY_PATH:-repo/vpinos-archive-keyring.asc}"
private_key_path="${PRIVATE_KEY_PATH:-.secrets/vpinos-archive-signing-key.asc}"

mkdir -p "$home" "$(dirname "$public_key_path")" "$(dirname "$private_key_path")"
chmod 700 "$home"

cat > "$home/key-params" <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: sign
Name-Real: ${name}
Name-Email: ${email}
Expire-Date: 0
%no-protection
%commit
EOF

gpg --batch --homedir "$home" --generate-key "$home/key-params"
fingerprint="$(gpg --batch --homedir "$home" --list-secret-keys --with-colons "$email" | awk -F: '/^fpr:/ {print $10; exit}')"

gpg --batch --homedir "$home" --armor --export "$fingerprint" > "$public_key_path"
gpg --batch --homedir "$home" --armor --export-secret-keys "$fingerprint" > "$private_key_path"

cat <<EOF
Generated repository signing key:
  Fingerprint: $fingerprint
  Public key:  $public_key_path
  Private key: $private_key_path

Add the private key file content to the GitHub secret APT_SIGNING_KEY.
The public key is safe to commit so clients can trust the repository.
EOF
