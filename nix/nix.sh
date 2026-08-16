#! /bin/bash
set -euo pipefail

if [[ "$(uname)" == "Darwin" ]]; then
  xcode-select --install
fi
printf 'Installing Nix\n'
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
mkdir -p ~/.config/home-manager
cp -r nix/flake.* nix/home.nix ~/.config/home-manager/
printf '\nConfiguring Home Manager\n'
nix run home-manager/master -- switch --flake . --impure
