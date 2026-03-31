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
# Retry logic: after a display change, macOS's wallpaper agent races with us to
# update the plist. Rather than a fixed sleep (which wastes time when it works and
# isn't long enough when it doesn't), we retry the Swift script up to 3 times with
# 3s gaps. First attempt often succeeds immediately.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Retry: the plist may not be ready immediately after a display change.
retries=3
while [[ $retries -gt 0 ]]; do
  if output=$(swift "$SCRIPT_DIR/reapply-wallpaper.swift" 2>&1); then
    echo "$(date '+%Y-%m-%d %H:%M:%S') $output"
    exit 0
  fi
  ((retries--))
  if [[ $retries -gt 0 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Retrying in 3s... ($retries attempts left)"
    sleep 3
  fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') Error: failed after retries: $output" >&2
exit 1
