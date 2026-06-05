#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZED_DIR="${ZED_DIR:-"$REPO_ROOT/sdk/zed"}"

sudo groupadd -f zed
sudo usermod -aG video,zed "$USER"

sudo cp "$REPO_ROOT/resources/system_rules/99-slabs.rules" /etc/udev/rules.d/
sudo chmod 644 /etc/udev/rules.d/99-slabs.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

sudo cp "$REPO_ROOT/resources/system_rules/60-zed-buffers.conf" /etc/sysctl.d/
sudo chmod 644 /etc/sysctl.d/60-zed-buffers.conf
sudo sysctl -p /etc/sysctl.d/60-zed-buffers.conf

echo "$ZED_DIR/lib" | sudo tee /etc/ld.so.conf.d/001-zed-local.conf >/dev/null
sudo ldconfig

echo "System rules applied. Unplug/replug the ZED 2i or reboot, then run scripts/check_connection.sh."
