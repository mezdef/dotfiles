#!/usr/bin/env bash
set -euo pipefail

# Install kanata as a LaunchDaemon (runs as root on boot)
# Usage: sudo ./install-daemon.sh

PLIST_SRC="$(dirname "$0")/../com.jtroo.kanata.plist"
PLIST_DST="/Library/LaunchDaemons/com.jtroo.kanata.plist"
LOG_DIR="/Library/Logs/Kanata"

if [ "$(id -u)" -ne 0 ]; then
  echo "Must run as root: sudo $0"
  exit 1
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Stop existing service if running
if launchctl list com.jtroo.kanata &>/dev/null; then
  echo "Stopping existing kanata service..."
  launchctl bootout system "$PLIST_DST" 2>/dev/null || true
fi

# Install plist
cp "$PLIST_SRC" "$PLIST_DST"
chown root:wheel "$PLIST_DST"
chmod 644 "$PLIST_DST"

# Load and start
launchctl bootstrap system "$PLIST_DST"
launchctl enable system/com.jtroo.kanata

echo "Kanata daemon installed and started."
echo "Logs: $LOG_DIR"
