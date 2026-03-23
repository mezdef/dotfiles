#!/usr/bin/env bash
# random-wallpaper.sh — Pick a random wallpaper and apply it to all desktops.
#
# Usage:
#   random-wallpaper.sh [wallpaper_dir]
#
# Arguments:
#   wallpaper_dir  Path to folder of images (default: ~/Library/CloudStorage/Dropbox/Resorces/wallpaper)
#
# Supported formats: jpg, jpeg, png, heic, webp
#
# Scheduled via launchd (com.marc.randomwallpaper.plist).
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

WALLPAPER_DIR="${1:-$HOME/Library/CloudStorage/Dropbox/Resorces/wallpaper}"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "Error: directory not found: $WALLPAPER_DIR" >&2
  exit 1
fi

shopt -s nullglob
files=()
for ext in jpg jpeg png heic webp; do
  files+=("$WALLPAPER_DIR"/*."$ext")
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Error: no image files found in $WALLPAPER_DIR" >&2
  exit 1
fi

wallpaper="${files[RANDOM % ${#files[@]}]}"
echo "$(date '+%Y-%m-%d %H:%M:%S') Setting wallpaper: $wallpaper"
osascript -e "tell application \"System Events\" to set picture of every desktop to \"$wallpaper\""
