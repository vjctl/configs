#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/nix-darwin"
NIX_DARWIN_HOSTNAME=$(scutil --get LocalHostName)
export NIX_DARWIN_HOSTNAME

echo "==> Setting up '$NIX_DARWIN_HOSTNAME' for '$(whoami)'"

# 1. Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "==> Homebrew is already installed"
fi

# Ensure Homebrew is in PATH
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. Install Nix
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
else
  echo "==> Nix is already installed"
fi

# Source Nix daemon
if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

# 3. Set up nix-darwin and flake.nix
echo "==> Setting up Nix $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

cp "$SCRIPT_DIR/flake.nix" "$CONFIG_DIR/flake.nix"
cp "$SCRIPT_DIR/flake.lock" "$CONFIG_DIR/flake.lock"

# 4. Initialize Git
cd "$CONFIG_DIR"
if [ ! -d ".git" ]; then
  git init
fi
git add flake.nix flake.lock

# 5. Build and activate the system
echo "==> Setting up nix-darwin & Home Manager"
nix run nix-darwin -- switch --flake "$CONFIG_DIR#$NIX_DARWIN_HOSTNAME" --impure

cp "$CONFIG_DIR/flake.lock" "$SCRIPT_DIR/flake.lock"

echo "==> Done!"
