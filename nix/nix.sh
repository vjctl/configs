#! /bin/bash
set -euo pipefail

if [[ "$(uname)" == "Darwin" ]]; then
  xcode-select --install
fi
if ! command -v nix >/dev/null 2>&1; then
  printf '\nInstalling Nix\n'
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi
mkdir -p ~/.config/home-manager
cp -r nix/flake.* nix/home.nix ~/.config/home-manager/
printf '\nConfiguring Home Manager\n'
nix run home-manager/master -- switch --flake . --impure
