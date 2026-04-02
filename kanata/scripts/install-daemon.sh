#!/usr/bin/env bash
set -euo pipefail

# Install kanata services:
#   - com.jtroo.kanata (LaunchDaemon, root): kanata itself
#   - com.jtroo.kanata-restarter (LaunchDaemon, root): restarts kanata when triggered
#   - com.jtroo.kanata-watcher (LaunchAgent, user): detects keyboard connect/disconnect
#
# The watcher runs as the user (for TCC/Input Monitoring access) and touches
# /tmp/kanata-restart-trigger. The restarter watches that file and runs
# launchctl kickstart as root.
#
# Usage: sudo ./install-daemon.sh

SCRIPT_DIR="$(dirname "$0")"
KANATA_SRC="$SCRIPT_DIR/../com.jtroo.kanata.plist"
KANATA_DST="/Library/LaunchDaemons/com.jtroo.kanata.plist"
RESTARTER_SRC="$SCRIPT_DIR/../com.jtroo.kanata-restarter.plist"
RESTARTER_DST="/Library/LaunchDaemons/com.jtroo.kanata-restarter.plist"
WATCHER_SRC="$SCRIPT_DIR/../com.jtroo.kanata-watcher.plist"
WATCHER_DST="$HOME/Library/LaunchAgents/com.jtroo.kanata-watcher.plist"
WATCHER_SWIFT="$SCRIPT_DIR/watch-keyboards.swift"
WATCHER_BIN="/opt/homebrew/bin/kanata-watcher"
LOG_DIR="/Library/Logs/Kanata"
REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_UID=$(id -u "$REAL_USER")

if [ "$(id -u)" -ne 0 ]; then
  echo "Must run as root: sudo $0"
  exit 1
fi

# Create log directory (writable by user for LaunchAgent logs)
mkdir -p "$LOG_DIR"
chmod 777 "$LOG_DIR"

# Compile keyboard watcher (needs to be a binary for Input Monitoring TCC permission)
echo "Compiling kanata-watcher..."
swiftc -O -o "$WATCHER_BIN" "$WATCHER_SWIFT"
chmod 755 "$WATCHER_BIN"

# Stop existing services
for svc in com.jtroo.kanata com.jtroo.kanata-restarter; do
  launchctl bootout system "/Library/LaunchDaemons/$svc.plist" 2>/dev/null || true
done
# Stop old watcher from system domain (migrating to user domain)
launchctl bootout system "/Library/LaunchDaemons/com.jtroo.kanata-watcher.plist" 2>/dev/null || true
rm -f "/Library/LaunchDaemons/com.jtroo.kanata-watcher.plist"
# Stop watcher from user domain
launchctl bootout "gui/$REAL_UID/com.jtroo.kanata-watcher" 2>/dev/null || true

# Install LaunchDaemons (root)
for src_dst in "$KANATA_SRC:$KANATA_DST" "$RESTARTER_SRC:$RESTARTER_DST"; do
  src="${src_dst%%:*}"
  dst="${src_dst##*:}"
  cp "$src" "$dst"
  chown root:wheel "$dst"
  chmod 644 "$dst"
done

# Install LaunchAgent (user)
mkdir -p "$(dirname "$WATCHER_DST")"
cp "$WATCHER_SRC" "$WATCHER_DST"
chown "$REAL_USER" "$WATCHER_DST"
chmod 644 "$WATCHER_DST"

# Load and start
launchctl bootstrap system "$KANATA_DST"
launchctl enable system/com.jtroo.kanata
launchctl bootstrap system "$RESTARTER_DST"
launchctl enable system/com.jtroo.kanata-restarter
launchctl bootstrap "gui/$REAL_UID" "$WATCHER_DST"
launchctl enable "gui/$REAL_UID/com.jtroo.kanata-watcher"

echo ""
echo "Installed:"
echo "  LaunchDaemon: com.jtroo.kanata (kanata itself)"
echo "  LaunchDaemon: com.jtroo.kanata-restarter (restart trigger)"
echo "  LaunchAgent:  com.jtroo.kanata-watcher (keyboard detection)"
echo "Logs: $LOG_DIR"
echo ""
echo "IMPORTANT: Add $WATCHER_BIN to Input Monitoring in"
echo "  System Settings > Privacy & Security > Input Monitoring"
