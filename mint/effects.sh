#!/usr/bin/env bash
set -euo pipefail

gsettings set org.cinnamon desktop-effects false
gsettings set org.cinnamon desktop-effects-on-dialogs false
gsettings set org.cinnamon desktop-effects-on-menus false
gsettings set org.cinnamon startup-animation false
gsettings set org.cinnamon desktop-effects-map 'none'
gsettings set org.cinnamon desktop-effects-close 'none'
gsettings set org.cinnamon desktop-effects-minimize 'none'
gsettings set org.cinnamon desktop-effects-change-size false
gsettings set org.cinnamon desktop-effects-workspace false
gsettings set org.cinnamon window-effect-speed 0
gsettings set org.cinnamon.desktop.interface enable-animations false
