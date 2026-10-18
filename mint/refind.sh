#!/usr/bin/env bash
set -euo pipefail

REFIND_DIR="/boot/efi/EFI/refind"
CONF="$REFIND_DIR/refind.conf"
THEME_LINE="include themes/refindTTT/theme.conf"

sudo apt update && sudo apt install -y refind
sudo refind-install
sudo mkdir -p "$REFIND_DIR/themes"
sudo git clone https://github.com/gutlessCGH/refindTTT.git "$REFIND_DIR/themes/refindTTT"
grep -qF "$THEME_LINE" "$CONF" || echo "$THEME_LINE" | sudo tee -a "$CONF" > /dev/null
sudo reboot
