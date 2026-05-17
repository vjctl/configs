#!/usr/bin/env bash
set -euo pipefail

module="asus_wmi"
param="fnlock_default"
param_file="/sys/module/$module/parameters/$param"
config_file="/etc/modprobe.d/alsa-base.conf"
config_line="options $module ${param}=N"

if [ -f "$param_file" ]; then
    if grep -qF "$config_line" "$config_file" 2>/dev/null; then
        echo -e "\nLOCK ALREADY DISABLED"
    else
        echo -e "# Disable $param at boot \n$config_line\n" | sudo tee -a "$config_file" >/dev/null
        sudo update-initramfs -u -k all
        echo -e "\nLOCK DISABLED \nReboot for changes to take effect."
    fi
    exit 0
fi

echo -e "\n$param_file does not exist"
exit 1
