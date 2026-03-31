#!/usr/bin/env bash
# random-wallpaper.sh — Pick a random wallpaper and apply it to all desktops.
#
# Usage:
#   random-wallpaper.sh [wallpaper_dir]
#
# Arguments:
#   wallpaper_dir  Path to folder of images (default: ~/Library/CloudStorage/Dropbox/Resources/wallpaper)
#
# Supported formats: jpg, jpeg, png, heic, webp
#
# Goals:
#   1. Shuffle wallpaper daily — one random image from the wallpaper folder.
#   2. Same image on every screen and desktop — macOS's built-in wallpaper shuffle
#      picks a different image per screen/Space, which we don't want.
#   3. Newly connected screens match — when a monitor is plugged in (or wakes from
#      a dock), it should show the same daily wallpaper, not revert to an old one.
#
# Architecture:
#   This shell script handles the Dropbox mount wait (cloud storage may not be
#   available at login), then delegates to random-wallpaper.swift for the actual
#   wallpaper setting. Swift is needed because:
#     - NSWorkspace API (only way to set wallpaper on connected screens) requires AppKit
#     - Direct plist manipulation (needed for disconnected monitors and Spaces) requires
#       Foundation's PropertyListSerialization for binary plist read/write
#   See random-wallpaper.swift for details on the two-phase approach.
#
# Companion: reapply-wallpaper.sh handles goal #3 — re-applies the current wallpaper
# when monitors are connected/disconnected (triggered by display config changes via
# launchd WatchPaths).
#
# Scheduled via launchd (com.marc.randomwallpaper.plist) — runs at login and daily at 7am.
# Logs to ~/Library/Logs/random-wallpaper.log when run by launchd.
#
# Deploy:
#   cd ~/dotfiles && stow macos
#   launchctl load ~/Library/LaunchAgents/com.marc.randomwallpaper.plist
#
# Manage:
#   launchctl list | grep randomwallpaper   # check if loaded
#   launchctl unload ~/Library/LaunchAgents/com.marc.randomwallpaper.plist  # stop
set -euo pipefail

WALLPAPER_DIR="${1:-$HOME/Library/CloudStorage/Dropbox/Resources/wallpaper}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Wait for Dropbox CloudStorage to mount (up to 2 minutes)
retries=24
while [[ ! -d "$WALLPAPER_DIR" && $retries -gt 0 ]]; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') Waiting for $WALLPAPER_DIR to mount..."
  sleep 5
  ((retries--))
done

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "Error: directory not found after waiting: $WALLPAPER_DIR" >&2
  exit 1
fi

wallpaper=$(WALLPAPER_DIR="$WALLPAPER_DIR" swift "$SCRIPT_DIR/random-wallpaper.swift")

echo "$(date '+%Y-%m-%d %H:%M:%S') Setting wallpaper: $wallpaper"
