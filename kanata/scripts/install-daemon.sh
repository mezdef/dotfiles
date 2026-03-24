#!/usr/bin/env bash
set -euo pipefail

# Install kanata and keyboard watcher as LaunchDaemons (run as root on boot)
# Usage: sudo ./install-daemon.sh

SCRIPT_DIR="$(dirname "$0")"
KANATA_SRC="$SCRIPT_DIR/../com.jtroo.kanata.plist"
KANATA_DST="/Library/LaunchDaemons/com.jtroo.kanata.plist"
WATCHER_SRC="$SCRIPT_DIR/../com.jtroo.kanata-watcher.plist"
WATCHER_DST="/Library/LaunchDaemons/com.jtroo.kanata-watcher.plist"
LOG_DIR="/Library/Logs/Kanata"

if [ "$(id -u)" -ne 0 ]; then
  echo "Must run as root: sudo $0"
  exit 1
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Stop existing services if running
for svc in com.jtroo.kanata com.jtroo.kanata-watcher; do
  if launchctl list "$svc" &>/dev/null; then
    echo "Stopping $svc..."
    launchctl bootout system "/Library/LaunchDaemons/$svc.plist" 2>/dev/null || true
  fi
done

# Install plists
for src_dst in "$KANATA_SRC:$KANATA_DST" "$WATCHER_SRC:$WATCHER_DST"; do
  src="${src_dst%%:*}"
  dst="${src_dst##*:}"
  cp "$src" "$dst"
  chown root:wheel "$dst"
  chmod 644 "$dst"
done

# Load and start
launchctl bootstrap system "$KANATA_DST"
launchctl enable system/com.jtroo.kanata
launchctl bootstrap system "$WATCHER_DST"
launchctl enable system/com.jtroo.kanata-watcher

echo "Kanata daemon and keyboard watcher installed and started."
echo "Logs: $LOG_DIR"
