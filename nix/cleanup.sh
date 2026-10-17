#!/usr/bin/env bash
set -euo pipefail

echo "⚠️ This will completely remove all Nix packages, Homebrew apps,"
echo "   nix-darwin, the /nix APFS volume, and Homebrew itself"
read -p "Are you sure you want to return to stock state? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "==> Cleanup aborted"
  exit 0
fi

# 1. Zap all Homebrew casks and formulae first
if command -v brew &>/dev/null; then
  echo "==> Zapping all installed Homebrew casks"
  casks=$(brew list --cask)
  if [ -n "$casks" ]; then
    brew uninstall --cask --zap --force $casks || true
  fi

  echo "==> Removing all installed Homebrew formulae"
  brews=$(brew list --formula)
  if [ -n "$brews" ]; then
    brew uninstall --formula --force $brews || true
  fi
fi

# 2. Uninstall nix-darwin (restores /etc/zshrc, PAM/TouchID, and system defaults)
if command -v darwin-uninstaller &>/dev/null; then
  echo "==> Running darwin-uninstaller"
  sudo darwin-uninstaller
elif command -v nix &>/dev/null; then
  echo "==> Running darwin-uninstaller via nix flake"
  nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller || true
fi

# 3. Uninstall Nix completely (removes /nix APFS volume and daemon)
if [ -x "/nix/nix-installer" ]; then
  echo "==> Uninstalling Nix via Determinate Systems uninstaller"
  /nix/nix-installer uninstall --no-confirm
else
  echo "==> /nix/nix-installer not found"
fi

# 4. Uninstall Homebrew
if command -v brew &>/dev/null; then
  echo "==> Uninstalling Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true
  sudo rm -rf /opt/homebrew /usr/local/Homebrew
fi

# 5. Remove Nix, Home Manager, and state directories
echo "==> Removing local Nix and Home Manager directories"
rm -rf \
  "$HOME/.config/nix-darwin" \
  "$HOME/.config/home-manager" \
  "$HOME/.nix-profile" \
  "$HOME/.nix-defexpr" \
  "$HOME/.nix-channels" \
  "$HOME/.local/state/nix" \
  "$HOME/.local/state/home-manager" \
  "$HOME/.cache/nix"

echo "==> Cleanup complete! Please reboot to finalize changes"
