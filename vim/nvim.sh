#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
git clone --depth 1 https://github.com/AstroNvim/template "$config_dir"

nvim "$@"
