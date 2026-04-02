#!/usr/bin/env bash
# reapply-wallpaper.sh — Re-apply the current wallpaper to all connected screens.
#
# Reads the wallpaper path from the wallpaper plist and sets it on every
# connected display via NSWorkspace. Also updates the plist for any new
# display UUIDs and Spaces so macOS's wallpaper agent doesn't revert them.
#
# Triggered by launchd when display configuration changes (monitor connect/disconnect).
# The launchd plist watches /Library/Preferences/com.apple.windowserver.displays.plist
# which changes whenever a monitor is connected or disconnected.
#
# Timing strategy: macOS's wallpaper agent races with us on display changes.
# It can apply stale cached wallpapers AFTER we've already set ours. To win:
#   1. Wait 2s for macOS to do its initial plist write
#   2. Apply our wallpaper (overwriting whatever macOS set)
#   3. Wait 3s and apply again to catch any late macOS overwrites
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_swift() {
  if output=$(swift "$SCRIPT_DIR/reapply-wallpaper.swift" 2>&1); then
    echo "$(date '+%Y-%m-%d %H:%M:%S') $output"
    return 0
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: $output" >&2
    return 1
  fi
}

# Let macOS wallpaper agent settle before we overwrite
sleep 2

# First pass
if ! run_swift; then
  sleep 3
  run_swift || true
fi

# Second pass to catch late macOS overwrites
sleep 3
run_swift || true
