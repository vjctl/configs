#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ ! -d "$config_dir" ]]; then
  git clone --depth 1 https://github.com/AstroNvim/template "$config_dir"
fi

nvim "$@"
