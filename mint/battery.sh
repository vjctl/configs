#!/usr/bin/env bash
set -euo pipefail

# 1. Detect battery name (e.g. BAT0, BAT1)
BATTERY_NAME=$(ls /sys/class/power_supply | grep -m1 '^BAT')
if [[ -z "$BATTERY_NAME" ]]; then
  echo "No battery found in /sys/class/power_supply. Exiting!"
  exit 1
fi
echo "Detected battery: $BATTERY_NAME"

# 2. Skip setup if threshold is already configured
THRESHOLD_FILE="/sys/class/power_supply/$BATTERY_NAME/charge_control_end_threshold"
if [[ -f "$THRESHOLD_FILE" ]]; then
  echo "charge_control_end_threshold already exists ($(cat "$THRESHOLD_FILE")%). Exiting!"
  exit 0
fi

# 3. Prompt user for threshold percentage (default: 60)
read -rp "Enter battery charge stop threshold % [60]: " CHARGE_STOP_THRESHOLD
CHARGE_STOP_THRESHOLD="${CHARGE_STOP_THRESHOLD:-60}"

# 4. Create the systemd service
SERVICE_FILE="/etc/systemd/system/battery-charge-threshold.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Set the battery charge threshold
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/bash -c 'echo ${CHARGE_STOP_THRESHOLD} > /sys/class/power_supply/${BATTERY_NAME}/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
EOF
echo "Created $SERVICE_FILE"

# 5. Enable and restart the service
sudo systemctl daemon-reload
sudo systemctl enable battery-charge-threshold.service
sudo systemctl restart battery-charge-threshold.service
echo "Service enabled and started"

# 6. Display charging status
echo ""
echo "Battery status: $(cat /sys/class/power_supply/"$BATTERY_NAME"/status)"
echo "Charge stop threshold: $(cat "$THRESHOLD_FILE" 2>/dev/null || echo "$CHARGE_STOP_THRESHOLD")%"
