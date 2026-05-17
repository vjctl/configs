#!/usr/bin/env bash
set -euo pipefail

DIRS=(DESKTOP DOWNLOAD TEMPLATES PUBLICSHARE DOCUMENTS MUSIC PICTURES VIDEOS)

echo "XDG User Directories:"
for i in "${!DIRS[@]}"; do
  printf "  %d) %-12s %s\n" "$i" "${DIRS[$i]}" "$(xdg-user-dir "${DIRS[$i]}")"
done

read -rp $'\nChoose [0-7]: ' CHOICE
XDG_NAME="${DIRS[$CHOICE]}"

read -rp "Enter new path [$(xdg-user-dir "$XDG_NAME")]: " NEW_PATH
NEW_PATH="${NEW_PATH:-$(xdg-user-dir "$XDG_NAME")}"

xdg-user-dirs-update --set "$XDG_NAME" "$NEW_PATH"
