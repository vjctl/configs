#!/usr/bin/env bash
set -euo pipefail

SSL_CERT_DIR="/etc/ssl/certs"
SSL_CERT="$SSL_CERT_DIR/ca-certificates.crt"
mkdir -p "$SSL_CERT_DIR"
security export -t certs -f pemseq -k /System/Library/Keychains/SystemRootCertificates.keychain -o root.pem
security export -t certs -f pemseq -k /Library/Keychains/System.keychain -o custom.pem
cat root.pem custom.pem | sudo tee "$SSL_CERT"

# --- Detect OS and add exports to shell rc file
rc_file="$HOME/.bashrc"
if [[ "$(uname -s)" == "Darwin" ]]; then
  rc_file="$HOME/.zshrc"
fi

if test -f "$rc_file"; then
  marker="# Added from ssl.sh"
  if ! grep -q "$marker" "$rc_file" 2>/dev/null; then
    read -rp "Export SSL variables to $rc_file? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      mkdir -p ~/.aws
      echo "[default]" > ~/.aws/config
      echo "ca_bundle = $SSL_CERT" >> ~/.aws/config
      echo "" >> "$rc_file"
      echo "$marker" >> "$rc_file"
      echo "SSL_CERT=\"$SSL_CERT\"" >> "$rc_file"
      echo "export SSL_CERT_FILE=\"\$SSL_CERT\"" >> "$rc_file"
      echo "export REQUESTS_CA_BUNDLE=\"\$SSL_CERT\"" >> "$rc_file"
      echo "export CURL_CA_BUNDLE=\"\$SSL_CERT\"" >> "$rc_file"
      echo "export AWS_CA_BUNDLE=\"\$SSL_CERT\"" >> "$rc_file"
      echo "export NODE_EXTRA_CA_CERTS=\"\$SSL_CERT\"" >> "$rc_file"
      echo "export JAVA_OPTS=\"-Djavax.net.ssl.trustStore=\$SSL_CERT\"" >> "$rc_file"
      echo "export GIT_SSL_CAINFO=\"\$SSL_CERT\"" >> "$rc_file"
      echo "git config --global http.sslCAInfo \"\$SSL_CERT\"" >> "$rc_file"
      printf '\nExported SSL variables to %s\n' "$rc_file" >&2
    else
      printf '\nSkipped shell exports\n' >&2
    fi
  fi
fi
