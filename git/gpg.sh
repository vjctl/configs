#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
  cat <<'EOF'
Usage:   gpg.sh <username> <email>
EOF
  exit 0
fi

username="$1"
email="$2"
script_dir="$(cd "$(dirname "$0")" && pwd)"

gen_gpg_key() {

  gpg --batch --pinentry-mode loopback --passphrase '' --generate-key <<GPGEOF
Key-Type: RSA
Key-Length: 4096
Name-Real: $username
Name-Email: $email
Expire-Date: 0
%commit
GPGEOF

  key_id=$(gpg --list-secret-keys --keyid-format=long "$email" \
    | grep 'sec' | head -1 | sed 's/.*\/\([A-F0-9]*\).*/\1/')

  gpg --armor --export "$key_id" > "$script_dir/${username}_gpg.pub"
  printf '\nDone. Public key saved to: %s/%s_gpg.pub\n' "$script_dir" "$username"
  printf 'Add it to GitHub: Settings > SSH and GPG keys > New GPG key\n'
}

config_git() {
  user_config="$HOME/.gitconfig-$username"
  cat > "$user_config" <<EOF
[user]
	name = $username
	email = $email
	signingkey = $key_id
EOF

  git_config="$HOME/.gitconfig"
  cat >> "$git_config" <<EOF

[includeIf "gitdir:~/Git/$username/"]
	path = ~/.gitconfig-$username

[includeIf "hasconfig:remote.*.url:https://github.com/$username/**"]
	path = ~/.gitconfig-$username

EOF
}

gen_gpg_key
config_git
