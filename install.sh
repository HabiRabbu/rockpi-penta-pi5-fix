#!/bin/bash
# rockpi-penta-pi5-fix install script
# Fixes the rockpi-penta package for Raspberry Pi 5 running Debian Trixie (gpiod v2)
# Also patches fan control to read SSD temperatures instead of CPU temperature.

set -e

echo "=== rockpi-penta Pi 5 Fix Installer ==="
echo ""

# Check we're running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo bash install.sh"
  exit 1
fi

# Check rockpi-penta is installed
if [ ! -f /usr/bin/rockpi-penta/fan.py ]; then
  echo "rockpi-penta does not appear to be installed."
  echo "Please install it first:"
  echo ""
  echo "  sudo apt install wget"
  echo "  wget https://github.com/radxa/rockpi-penta/releases/download/v0.2.2/rockpi-penta-0.2.2.deb"
  echo "  sudo apt install -y ./rockpi-penta-0.2.2.deb"
  echo ""
  exit 1
fi

# Install smartmontools (required for SSD temp reading)
echo "[1/4] Installing smartmontools..."
apt install -y smartmontools

# Back up original files
echo "[2/4] Backing up original files..."
cp /usr/bin/rockpi-penta/fan.py /usr/bin/rockpi-penta/fan.py.bak
cp /usr/bin/rockpi-penta/misc.py /usr/bin/rockpi-penta/misc.py.bak
echo "  Backups saved as fan.py.bak and misc.py.bak"

# Copy patched files
echo "[3/4] Applying patches..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/patches/fan.py" /usr/bin/rockpi-penta/fan.py
cp "$SCRIPT_DIR/patches/misc.py" /usr/bin/rockpi-penta/misc.py

# Copy recommended config (only if user hasn't already customised it)
if [ ! -f /etc/rockpi-penta.conf ]; then
  echo "  Installing default config..."
  cp "$SCRIPT_DIR/rockpi-penta.conf" /etc/rockpi-penta.conf
else
  echo "  /etc/rockpi-penta.conf already exists, skipping. See rockpi-penta.conf in this repo for recommended SSD thresholds."
fi

# Restart service
echo "[4/4] Restarting rockpi-penta service..."
systemctl restart rockpi-penta.service
sleep 3
systemctl status rockpi-penta.service --no-pager

echo ""
echo "=== Done! ==="
echo "If the service shows 'active (running)' above, everything is working."
echo "You can check/adjust fan thresholds in /etc/rockpi-penta.conf"
