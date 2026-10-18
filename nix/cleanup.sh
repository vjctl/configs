#!/usr/bin/env bash
set -euo pipefail

echo "⚠️ This will completely remove all Nix packages, Homebrew apps,"
echo "   nix-darwin, the /nix APFS volume, and Homebrew itself"
read -p "Are you sure you want to return to stock state? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Cleanup aborted"
  exit 0
fi

if command -v brew &>/dev/null; then
  echo "1. Zapping all Homebrew casks"
  casks=$(brew list --cask)
  if [ -n "$casks" ]; then
    brew uninstall --cask --zap --force $casks || true
  fi

  echo "2. Removing all Homebrew formulae"
  brews=$(brew list --formula)
  if [ -n "$brews" ]; then
    brew uninstall --formula --force $brews || true
  fi
fi

# 3. nix-darwin: restores /etc/zshrc, PAM/TouchID, and system defaults
if command -v darwin-uninstaller &>/dev/null; then
  echo "3. Running darwin-uninstaller"
  sudo darwin-uninstaller
elif command -v nix &>/dev/null; then
  echo "Running darwin-uninstaller via nix flake"
  nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller || true
fi

# 4. Nix: removes /nix APFS volume and daemon
if [ -x "/nix/nix-installer" ]; then
  echo "4. Uninstalling Nix via Determinate Systems uninstaller"
  /nix/nix-installer uninstall --no-confirm
else
  echo "/nix/nix-installer not found"
fi

if command -v brew &>/dev/null; then
  echo "5. Uninstalling Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true
  sudo rm -rf /opt/homebrew /usr/local/Homebrew
fi

echo "6. Removing Nix and Home Manager directories"
rm -rf \
  "$HOME/.config/nix-darwin" \
  "$HOME/.config/home-manager" \
  "$HOME/.nix-profile" \
  "$HOME/.nix-defexpr" \
  "$HOME/.nix-channels" \
  "$HOME/.local/state/nix" \
  "$HOME/.local/state/home-manager" \
  "$HOME/.cache/nix"

echo "Reboot to complete cleanup!"
