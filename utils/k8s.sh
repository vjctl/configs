#!/usr/bin/env bash
set -euo pipefail

architecture="amd64"
if test "$(uname -m)" = aarch64; then
  # For linux running ARM the output is aarch64, but the package names will be called arm64
  architecture="arm64"
fi

binaries="\
https://dl.k8s.io/release/v1.33.0/bin/linux/${architecture}/kubectl
https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.53.2/ytt-linux-${architecture}
https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.47.3/kbld-linux-${architecture}
https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.65.1/kapp-linux-${architecture}
https://github.com/pomerium/cli/releases/download/v0.32.2/pomerium-cli-linux-${architecture}.tar.gz
"

# --- default to POSIX mode for Linux/OSX compatibility
sed="sed --posix"
osx=false

# --- check if we're running on OSX
uname="$(uname -s)"
if test "$uname" = Darwin -o -n "${FORCE_DARWIN:-}"; then
  echo -e "\nRunning on OSX" >&2
  sed="sed"
  osx=true
fi

# --- Ensure docker-credential-osxkeychain is installed on macOS
if $osx; then
  if ! command -v docker-credential-osxkeychain >/dev/null 2>&1; then
    echo "docker-credential-osxkeychain not found, attempting to install via Homebrew"
    if command -v brew >/dev/null 2>&1; then
      brew install docker-credential-helper
    else
      echo "Please install Homebrew or Docker Desktop to get docker-credential-osxkeychain"
    fi
  fi
fi

# --- tempdir for config
_SELF="$(readlink -f "${BASH_SOURCE[0]}")"
_HERE="$(dirname "${_SELF}")"
_ROOT="$(dirname "${_HERE}")"

tmpcfg="$HOME/tmp"
mkdir -p "$tmpcfg"

# --- determine real location of bootstrap script
bashsrc="${BASH_SOURCE[0]}"
srcpath="$(cd "$( dirname $( test "$osx" = true && readlink "$bashsrc" || realpath "$bashsrc" ) )" >/dev/null 2>&1 && pwd)"

# --- determine project root
projectroot="$(cd "$srcpath/.." >/dev/null 2>&1 && pwd)"

# --- save downloaded binaries to BINPATH
binpath="${BINPATH:-}"
test -z "$binpath" && binpath="$HOME/.k8s-bin"
mkdir -p "$binpath"
mkdir -p "$binpath"/.md5

{
  echo "Checking binaries:"
  for url in $binaries; do
    if test "$osx" = true; then
      url="$(echo "$url" | $sed -e "s/linux64/osx-amd64/g" -e "s/linux/darwin/g" -e "s/Linux/Darwin/g" -e "s/unknown/apple/g")"
    fi

    url_hash="$(echo "$url" | openssl md5 -r | awk '{print $1}')"
    download_base="${url##*/}"
    download_name="$(echo $download_base | $sed -e 's/.tar.gz//' -e 's/.zip//')"
    download_name_short="$(echo $download_name | $sed -e 's/[-_][lL]inux.*//' -e 's/[-_][dD]arwin.*//' -e 's/[-_]x86.*//' -e 's/[-_]v[0-9\.]\{2,\}.*//' -e 's/[-_][0-9\.]\{2,\}.*//')"

    printf "%-130s ... %-24s " "$url" "[$download_name_short]"

    if test -x "$binpath/$download_name_short" -a -f "${binpath}/.md5/${download_name_short}"; then
      current_hash="$(cat "${binpath}/.md5/${download_name_short}")"
      if test "$url_hash" = "$current_hash"; then
        echo "up to date"
        continue
      else
        echo "needs update"
      fi
    else
      echo "downloading"
    fi

    echo "$url_hash" > "${binpath}/.md5/${download_name_short}"

    tmpdir="$(mktemp -d)"
    curl -s -L -o "$tmpdir/$download_base" "$url"

    case "$download_base" in
      *.tar.gz|*.tgz)
        tar -xzf "$tmpdir/$download_base" -C "$tmpdir"
        ;;
      *.zip)
        unzip -qq -d "$tmpdir" "$tmpdir/$download_base"
        ;;
      "$download_name")
        ;;
      *)
        mv "$tmpdir/$download_base" "$tmpdir/$download_name"
    esac

    find "$tmpdir"/ \
      -type f \( -name "$download_name" -o -name "$download_name_short" \) \
      -exec cp '{}' "$binpath/$download_name_short" ';'

    chmod +x "$binpath/$download_name_short"

    if ! file -b "$binpath/$download_name_short" | grep -i -q executable; then
      echo -e "\n Failed to download $download_name_short - you'll have to install it yourself\n"
      rm "$binpath/$download_name_short"
    fi

    rm -rf "$tmpdir"
  done

  # Generate combined configs
  env KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}:$srcpath/config/kubeconfig.yaml" \
    "$binpath/kubectl" config view --raw \
    > "$tmpcfg/kubeconfig.yaml"

  cp "$DOCKER_CONFIG" "$tmpcfg/docker.json"

  if ! command -v k8s >/dev/null; then
    echo -e "\nSymlink this script for convenience, for example:\n\n    ln -s $projectroot/scripts/bootstrap.sh /usr/local/bin/k8s\n"
  fi
} >&2

export \
  PATH="$binpath:$PATH" \
  PS1="[k8s] ${PS1:-}" \
  K8S=1 \
  AWS_CONFIG_FILE="$projectroot/aws-vault.cfg" \
  KUBECONFIG="$tmpcfg/kubeconfig.yaml" \
  DOCKER_CONFIG="$tmpcfg/docker.json"

args="$@"
test -n "$args" || args="$SHELL"
exec $args

# --- Add exports to shell rc file if not already present
case "${SHELL:-/bin/bash}" in
  */zsh)  rc_file="$HOME/.zshrc"  ;;
  */fish) rc_file="$HOME/.config/fish/config.fish" ;;
  *)      rc_file="$HOME/.bashrc" ;;
esac

if test -f "$rc_file"; then
  marker="# Added from k8s.sh"
  if ! grep -q "$marker" "$rc_file" 2>/dev/null; then
    read -rp "Export variables to $rc_file? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      echo "" >> "$rc_file"
      echo "$marker" >> "$rc_file"
      echo "export PATH=\"$binpath:\$PATH\"" >> "$rc_file"
      echo "export AWS_CONFIG_FILE=\"$projectroot/aws-vault.cfg\"" >> "$rc_file"
      echo "export KUBECONFIG=\"$tmpcfg/kubeconfig.yaml\"" >> "$rc_file"
      echo "export DOCKER_CONFIG=\"$tmpcfg/docker\"" >> "$rc_file"
      printf "Exported environment variables to $rc_file" >&2
    else
      printf "Skipped shell exports" >&2
    fi
  fi
fi
